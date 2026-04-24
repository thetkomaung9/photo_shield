# Social Console Setup

This app now includes a unified onboarding and monitoring flow for Facebook,
Instagram, Kakao, and Naver. The code runs in demo mode until the provider
console values below are supplied.

## Required runtime values

Use `--dart-define` or your CI/CD secret injection for these keys:

```sh
flutter run \
  --dart-define=META_APP_ID=1234567890 \
  --dart-define=META_APP_TOKEN=1234567890|app-secret \
  --dart-define=META_USER_TOKEN=EAAB... \
  --dart-define=META_IG_USER_ID=1784... \
  --dart-define=INSTAGRAM_CLIENT_ID=your-instagram-app-id \
  --dart-define=INSTAGRAM_REDIRECT_URI=photoshield-instagram://auth \
  --dart-define=KAKAO_NATIVE_APP_KEY=your-kakao-native-key \
  --dart-define=KAKAO_CALLBACK_SCHEME=photoshield-kakao \
  --dart-define=NAVER_CLIENT_ID=your-naver-client-id \
  --dart-define=NAVER_CLIENT_SECRET=your-naver-client-secret \
  --dart-define=NAVER_SERVICE_NAME=PhotoShield \
  --dart-define=NAVER_REDIRECT_URI=photoshield-naver://auth \
  --dart-define=KAKAO_MONITOR_ENDPOINT=https://api.photoshield.kr/v1/monitoring/kakao/detections \
  --dart-define=NAVER_MONITOR_ENDPOINT=https://api.photoshield.kr/v1/monitoring/naver/detections \
  --dart-define=MONITOR_KEYWORDS=내사진,프로필도용,무단도용
```

## Facebook / Instagram (Meta)

1. Create a Meta app and add Facebook Login plus Instagram API products.
2. Add your Android package name and iOS bundle id in the Meta dashboard.
3. Configure valid OAuth redirect URIs for `photoshield-instagram://auth`.
4. Generate a long-lived user token for the connected Facebook or Instagram account.
5. If you need hashtag search or Business Discovery, request the required Meta features and scopes documented in [docs/META_API_RESEARCH.md](/Users/tkm/Desktop/photo_shield/photo_shield/docs/META_API_RESEARCH.md).

## Kakao

1. Create an app in Kakao Developers.
2. Enable Kakao Login and add your Android/iOS package identifiers.
3. Register the native app key and callback URI `photoshield-kakao://oauth`.
4. Add consent items for profile basics and email if your backend requires them.

## Naver

1. Create an application in Naver Developers.
2. Register Android/iOS app identifiers and the callback URI `photoshield-naver://auth`.
3. Enable Naver Login and record the client id, client secret, and service name.
4. Confirm the redirect scheme matches the app callback you ship.

## Firebase push setup still required

The app already initializes Firebase Messaging. For live push alerts, make sure:

1. Android uses a valid `google-services.json`.
2. iOS uses a valid `GoogleService-Info.plist` and APNs key/certificate.
3. Your backend sends FCM notifications for suspicious detections and onboarding completion.

## What is still backend-dependent

The unified monitoring pipeline in the Flutter app now calls backend endpoints
for Kakao and Naver detection ingestion. The app expects payloads at
`KAKAO_MONITOR_ENDPOINT` and `NAVER_MONITOR_ENDPOINT` that return either a raw
list or a `{ detections: [...] }` envelope, with each detection containing
`id` or `detectionId`, `url` or `foundUrl`, optional `imageUrl` or
`screenshotUrl`, `similarity`, `detectedAt`, `status`, and `originalPhotoId`.

Instagram app login still requires a backend token exchange endpoint at
`/social/instagram/exchange` or an override on top of the app API base URL so
the client never embeds the Instagram app secret.
