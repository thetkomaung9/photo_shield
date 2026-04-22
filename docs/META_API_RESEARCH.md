# Meta Graph API Research Notes — PhotoShield Korea

This document summarises the current (April 2026) state of the Meta Graph API
relevant to the PhotoShield use case (detecting unauthorised use of a user's
photos on Facebook and Instagram). The accompanying `facebook_api_service.dart`
and `instagram_api_service.dart` files implement what is described here.

## 1. Instagram

The legacy **Instagram Basic Display API** was permanently shut down on
**December 4, 2024**. There is no longer a "consumer" tier of Instagram APIs.
The only supported pathways are the two Graph-API based products:

| Product | Login | Base URL | Best for |
| --- | --- | --- | --- |
| Instagram API with Instagram Login (a.k.a. *Instagram Direct Login*, launched July 2024) | Instagram OAuth | `https://graph.instagram.com` | Consumer-style flows, mobile apps |
| Instagram API with Facebook Login for Business | Facebook OAuth + linked Facebook Page | `https://graph.facebook.com` | Hashtag search, Business Discovery, copyright |

### Endpoints actually used by PhotoShield

| Capability | Endpoint | Notes |
| --- | --- | --- |
| Token validation | `GET /debug_token` | Used to detect *demo mode* vs *connected mode*. |
| Connected account info | `GET /me?fields=user_id,username,account_type,profile_picture_url,media_count` | Works on `graph.instagram.com`. |
| User's own media | `GET /{ig-user-id}/media?fields=id,media_type,media_url,thumbnail_url,permalink,caption,timestamp` | Used to verify monitoring is live. |
| Hashtag ID lookup | `GET /ig_hashtag_search?user_id={ig-id}&q={tag}` | Max **30 unique hashtags / 7 days**. |
| Recent media for hashtag | `GET /{hashtag-id}/recent_media?user_id={ig-id}&fields=id,media_type,media_url,permalink,caption,like_count,timestamp` | Only **public** posts from the **last 24 hours**. `username` cannot be requested. |
| Top media for hashtag | `GET /{hashtag-id}/top_media?...` | Same shape, popularity-ranked. |
| Public business profile lookup | `GET /{ig-id}?fields=business_discovery.username({username}){followers_count,media_count,profile_picture_url,media{id,media_type,media_url,permalink,caption}}` | Only Business / Creator accounts. Cannot read private accounts. |
| Public post embed (any IG post) | `GET /instagram_oembed?url={post-url}&access_token={app-token}` | Needs **Meta oEmbed Read**. App access token works. **5M requests / 24h** with app token. |

### Required permissions / features

* `instagram_business_basic` — read profile + media of the connected pro account.
* `instagram_basic` — required for hashtag search via Facebook Login flow.
* `Instagram Public Content Access` (feature) — required for hashtag endpoints.
* `pages_read_engagement` — needed when the token comes from a Business-Manager-granted Page role.

In **Development / Standard Access** mode the app developer can already exercise
all of these endpoints against their own connected Instagram pro account without
business verification. **Advanced Access** (and therefore App Review +
business verification) is only required when the app has external end users.

### Hard limits

* 30 unique hashtags per IG account per rolling 7-day window.
* Recent-media is limited to the last 24 hours of posts.
* You **cannot** read another user's private feed via the API. There is no
  public "search for username" endpoint that returns photos.

## 2. Facebook

* `GET /{page-id}` and `GET /{page-id}/photos` — readable on any **public** Page
  with any valid access token (an app access token is sufficient for many
  fields).
* `GET /{page-id}/picture?type=large&redirect=false` — public profile picture.
* `GET /oembed_post?url={post-url}&access_token={app-token}` — public post embed
  (Meta oEmbed Read). 5M req/day.
* `GET /debug_token?input_token={t}&access_token={app-token}` — token health.
* The **Pages Search** endpoint (`/pages/search?q=...`) needs the
  `Page Public Metadata Access` feature, which requires App Review. It is **not**
  usable on the free tier.
* Searching general Facebook users by name is **deprecated** since v8.0.

## 3. Intellectual-property / takedown tooling

* **Meta Brand Rights Protection** — dashboard-based; allows up to 200
  reference images per brand. No public REST API for image submission.
* **Rights Manager** — primarily for video/audio fingerprinting on FB/IG.
* **Intellectual Property Reporting API** — programmatic copyright/trademark
  reporting. Requires a verified Business account and an authorised app via an
  application form. Not available on the free tier.

PhotoShield therefore implements takedown by deep-linking the user to the
relevant in-app report URL (`https://www.facebook.com/help/contact/...` and
`https://help.instagram.com/contact/...`).

## 4. Reverse image search

There is no Meta-provided reverse image search endpoint. Realistic options:

* **TinEye API** — paid, image fingerprinting.
* **SerpAPI Google / Bing Visual Search** — paid wrappers.
* **Bing Image Search v7** — retired in August 2025.

PhotoShield treats reverse image search as an optional, externally pluggable
service; the Dart code exposes a stub the user can wire up later.

## 5. Token / configuration model used in the app

The app reads three optional environment values via `--dart-define`:

```
flutter run \
  --dart-define=META_APP_ID=000000000000000 \
  --dart-define=META_APP_TOKEN=000000000000000|aaaaaaaaaaaaaaaaaaaaaaaaaa \
  --dart-define=META_USER_TOKEN=EAA...
```

* `META_APP_ID` — the Meta app numeric id.
* `META_APP_TOKEN` — `{app_id}|{app_secret}`, only needed if the app calls
  oEmbed from a backend / trusted client.
* `META_USER_TOKEN` — long-lived Instagram or Facebook user access token (the
  one obtained from the App Dashboard "Generate token" button).

If none of these are set, the services automatically fall back to **demo mode**
and return locally-curated mock detections (so the dashboard, detection list
and report flow remain interactive without network access).
