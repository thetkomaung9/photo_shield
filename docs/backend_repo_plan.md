# PhotoShield Backend Repo Plan

This plan is scoped to the current Flutter app in this repository. It assumes:

- Flutter remains the mobile client.
- A new Python backend is added under `backend/`.
- The existing demo-mode providers are replaced incrementally, not all at once.
- Detection is limited to policy-safe sources: reverse-image search providers, public web pages, and platform APIs that explicitly permit the access pattern.

## 1. Target Monorepo Layout

```text
photo_shield/
├── lib/                         # existing Flutter app
├── docs/
│   ├── META_API_RESEARCH.md
│   └── backend_repo_plan.md
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   ├── deps.py
│   │   │   ├── router.py
│   │   │   └── v1/
│   │   │       ├── auth.py
│   │   │       ├── users.py
│   │   │       ├── photos.py
│   │   │       ├── detections.py
│   │   │       ├── scan.py
│   │   │       ├── monitoring.py
│   │   │       ├── notifications.py
│   │   │       ├── reports.py
│   │   │       └── devices.py
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   ├── security.py
│   │   │   ├── logging.py
│   │   │   └── database.py
│   │   ├── db/
│   │   │   ├── base.py
│   │   │   ├── models/
│   │   │   │   ├── user.py
│   │   │   │   ├── device.py
│   │   │   │   ├── reference_photo.py
│   │   │   │   ├── reference_embedding.py
│   │   │   │   ├── source_config.py
│   │   │   │   ├── scan_job.py
│   │   │   │   ├── candidate_profile.py
│   │   │   │   ├── candidate_image.py
│   │   │   │   ├── detection.py
│   │   │   │   ├── notification.py
│   │   │   │   ├── report_case.py
│   │   │   │   └── audit_log.py
│   │   │   └── session.py
│   │   ├── schemas/
│   │   │   ├── common.py
│   │   │   ├── auth.py
│   │   │   ├── photo.py
│   │   │   ├── detection.py
│   │   │   ├── monitoring.py
│   │   │   ├── notification.py
│   │   │   ├── report.py
│   │   │   └── scan.py
│   │   ├── services/
│   │   │   ├── storage_service.py
│   │   │   ├── photo_service.py
│   │   │   ├── embedding_service.py
│   │   │   ├── matching_service.py
│   │   │   ├── risk_service.py
│   │   │   ├── detection_service.py
│   │   │   ├── notification_service.py
│   │   │   └── report_service.py
│   │   ├── connectors/
│   │   │   ├── base.py
│   │   │   ├── tineye.py
│   │   │   ├── google_vision_web.py
│   │   │   ├── meta_public.py
│   │   │   ├── naver_public.py
│   │   │   └── kakao_public.py
│   │   ├── workers/
│   │   │   ├── celery_app.py
│   │   │   ├── tasks_scan.py
│   │   │   ├── tasks_match.py
│   │   │   ├── tasks_notify.py
│   │   │   └── tasks_cleanup.py
│   │   ├── utils/
│   │   │   ├── image.py
│   │   │   ├── hashing.py
│   │   │   └── time.py
│   │   └── main.py
│   ├── alembic/
│   ├── tests/
│   │   ├── api/
│   │   ├── services/
│   │   ├── workers/
│   │   └── fixtures/
│   ├── scripts/
│   │   ├── seed_demo.py
│   │   └── backfill_embeddings.py
│   ├── Dockerfile
│   ├── pyproject.toml
│   ├── alembic.ini
│   └── .env.example
├── docker-compose.yml
└── README.md
```

## 2. Runtime Architecture

### Backend choices

- API: FastAPI
- ORM: SQLAlchemy 2.x
- Database: PostgreSQL + `pgvector`
- Queue: Celery + Redis
- ML runtime: PyTorch-compatible model stack, with `insightface` as the initial ArcFace implementation
- Object storage: S3-compatible bucket for uploaded reference photos and captured evidence thumbnails

### Separation of responsibilities

- FastAPI handles user-facing CRUD, auth, review actions, scan control, and dashboard reads.
- Celery handles long-running work: provider fetch, candidate image processing, embedding extraction, matching, and notifications.
- Connectors only return public, policy-permitted candidates.
- Risk scoring is centralized in one service so thresholds can be tuned without rewriting connectors.

## 3. Database Schema

Use PostgreSQL. Prefer UUID primary keys and `timestamptz` everywhere.

### `users`

```sql
id uuid primary key
email text unique not null
name text not null
password_hash text null
notification_enabled boolean not null default true
created_at timestamptz not null
updated_at timestamptz not null
```

### `device_tokens`

```sql
id uuid primary key
user_id uuid not null references users(id)
platform text not null           -- ios, android, web
fcm_token text not null unique
is_active boolean not null default true
last_seen_at timestamptz not null
created_at timestamptz not null
```

### `reference_photos`

```sql
id uuid primary key
user_id uuid not null references users(id)
storage_key text not null
thumbnail_key text null
sha256 text not null
status text not null             -- uploading, processing, monitoring, rejected
quality_score numeric(5,4) null
face_count int not null default 0
primary_face_bbox jsonb null
rejection_reason text null
created_at timestamptz not null
updated_at timestamptz not null
```

### `reference_embeddings`

```sql
id uuid primary key
reference_photo_id uuid not null references reference_photos(id)
user_id uuid not null references users(id)
model_name text not null         -- arcface_r100_v1
embedding vector(512) not null
embedding_norm numeric(8,6) not null
pose_yaw numeric(6,3) null
pose_pitch numeric(6,3) null
blur_score numeric(8,4) null
created_at timestamptz not null
```

Indexes:

- `ivfflat` or `hnsw` index on `embedding`
- btree on `(user_id, model_name)`

### `source_configs`

```sql
id uuid primary key
user_id uuid not null references users(id)
source_type text not null        -- tineye, google_vision_web, meta_public, naver_public
is_enabled boolean not null default true
config jsonb not null default '{}'
created_at timestamptz not null
updated_at timestamptz not null
unique(user_id, source_type)
```

### `scan_jobs`

```sql
id uuid primary key
user_id uuid not null references users(id)
trigger_type text not null       -- manual, scheduled, retry
status text not null             -- queued, running, completed, failed, cancelled
progress int not null default 0
current_stage text null          -- discover, download, embed, match, notify
current_source text null
started_at timestamptz null
finished_at timestamptz null
error_message text null
stats jsonb not null default '{}'
created_at timestamptz not null
```

Suggested `stats` keys:

- `sources_total`
- `sources_completed`
- `candidates_found`
- `candidate_images_processed`
- `matches_flagged`

### `candidate_profiles`

```sql
id uuid primary key
source_type text not null
external_profile_id text null
profile_url text not null
username text null
display_name text null
bio text null
avatar_url text null
metadata jsonb not null default '{}'
first_seen_at timestamptz not null
last_seen_at timestamptz not null
unique(source_type, profile_url)
```

### `candidate_images`

```sql
id uuid primary key
candidate_profile_id uuid null references candidate_profiles(id)
source_type text not null
image_url text not null
storage_key text null
sha256 text null
phash text null
face_count int not null default 0
status text not null             -- queued, downloaded, processed, no_face, failed
captured_at timestamptz null
created_at timestamptz not null
unique(source_type, image_url)
```

### `candidate_embeddings`

```sql
id uuid primary key
candidate_image_id uuid not null references candidate_images(id)
model_name text not null
embedding vector(512) not null
face_bbox jsonb not null
face_index int not null default 0
created_at timestamptz not null
```

### `detections`

This table should map cleanly to the existing Flutter `Detection` model in
`lib/shared/models/detection.dart`.

```sql
id uuid primary key
user_id uuid not null references users(id)
candidate_profile_id uuid null references candidate_profiles(id)
candidate_image_id uuid null references candidate_images(id)
reference_photo_id uuid null references reference_photos(id)
platform text not null
found_url text not null
screenshot_url text null
similarity numeric(6,5) not null
risk_level text not null         -- low, medium, high
status text not null             -- unread, read, reported, false_positive
report_url text null
evidence jsonb not null default '{}'
first_detected_at timestamptz not null
last_detected_at timestamptz not null
created_at timestamptz not null
updated_at timestamptz not null
```

Suggested `evidence` keys:

- `source_type`
- `matched_model`
- `reference_photo_id`
- `candidate_face_bbox`
- `username_similarity`
- `display_name_similarity`
- `duplicate_hits`
- `provider_response_excerpt`

### `notifications`

This maps to `lib/shared/models/notification_item.dart`.

```sql
id uuid primary key
user_id uuid not null references users(id)
detection_id uuid null references detections(id)
type text not null               -- info, warning, danger
message text not null
is_read boolean not null default false
delivered_push boolean not null default false
delivered_email boolean not null default false
created_at timestamptz not null
read_at timestamptz null
```

### `report_cases`

```sql
id uuid primary key
user_id uuid not null references users(id)
detection_id uuid not null references detections(id)
status text not null             -- draft, exported, submitted
pdf_storage_key text null
payload jsonb not null default '{}'
created_at timestamptz not null
updated_at timestamptz not null
```

### `audit_logs`

```sql
id uuid primary key
user_id uuid null references users(id)
action text not null
entity_type text not null
entity_id uuid null
metadata jsonb not null default '{}'
created_at timestamptz not null
```

## 4. FastAPI Endpoint Spec

Base path: `/v1`

JWT auth is sufficient for the first version. The Flutter app already sends
`Authorization: Bearer ...` via `ApiService`.

### Auth

#### `POST /auth/signup`

Request:

```json
{
  "name": "Kim",
  "email": "kim@example.com",
  "password": "strong-password"
}
```

Response:

```json
{
  "access_token": "jwt",
  "refresh_token": "jwt",
  "user": {
    "user_id": "uuid",
    "name": "Kim",
    "email": "kim@example.com",
    "notification_enabled": true,
    "created_at": "2026-04-25T10:00:00Z"
  }
}
```

#### `POST /auth/login`

Same response shape as signup.

#### `POST /auth/refresh`

Returns a new access token.

### Devices / Push

#### `POST /devices/push-token`

Used by `PushNotificationService` after FCM token retrieval.

Request:

```json
{
  "platform": "android",
  "fcm_token": "token"
}
```

Response:

```json
{
  "ok": true
}
```

### Photos

#### `GET /photos`

Response must match `Photo.fromJson` in `lib/shared/models/photo.dart`.

```json
[
  {
    "photo_id": "uuid",
    "thumbnail_url": "https://cdn.../thumb.jpg",
    "registered_at": "2026-04-25T10:00:00Z",
    "status": "monitoring"
  }
]
```

#### `POST /photos`

Multipart upload:

- `file`
- optional `label`

Response:

```json
{
  "photo_id": "uuid",
  "thumbnail_url": "https://cdn.../thumb.jpg",
  "registered_at": "2026-04-25T10:00:00Z",
  "status": "processing"
}
```

Behavior:

- Store original image.
- Enqueue embedding extraction.
- Reject uploads with no detectable face or poor quality.

#### `DELETE /photos/{photo_id}`

Response:

```json
{
  "ok": true
}
```

### Detections

#### `GET /detections`

Query params:

- `status`
- `risk_level`
- `limit`
- `cursor`

Response:

```json
{
  "items": [
    {
      "detection_id": "uuid",
      "platform": "instagram",
      "found_url": "https://instagram.com/...",
      "screenshot_url": "https://cdn.../evidence.jpg",
      "similarity": 0.9132,
      "original_photo_id": "uuid",
      "detected_at": "2026-04-25T10:00:00Z",
      "status": "unread",
      "report_url": "https://help.instagram.com/contact/383679321740945"
    }
  ],
  "next_cursor": null
}
```

`detected_at` should be sourced from `last_detected_at` for compatibility with
the existing Flutter model.

#### `GET /detections/{detection_id}`

Return the same shape as list item plus optional details:

```json
{
  "detection_id": "uuid",
  "platform": "instagram",
  "found_url": "https://instagram.com/...",
  "screenshot_url": "https://cdn.../evidence.jpg",
  "similarity": 0.9132,
  "original_photo_id": "uuid",
  "detected_at": "2026-04-25T10:00:00Z",
  "status": "unread",
  "report_url": "https://help.instagram.com/contact/383679321740945",
  "risk_level": "high",
  "evidence": {
    "username_similarity": 0.7,
    "matched_model": "arcface_r100_v1"
  }
}
```

#### `PATCH /detections/{detection_id}`

Request:

```json
{
  "status": "read"
}
```

Allowed transitions:

- `unread -> read`
- `read -> false_positive`
- `read -> reported`
- `unread -> false_positive`

### Notifications

#### `GET /notifications`

Response:

```json
[
  {
    "notification_id": "uuid",
    "type": "danger",
    "message": "Potential impersonation detected on Instagram (91%)",
    "detection_id": "uuid",
    "is_read": false,
    "created_at": "2026-04-25T10:00:00Z"
  }
]
```

#### `PATCH /notifications/{notification_id}`

Request:

```json
{
  "is_read": true
}
```

### Monitoring / Dashboard

#### `GET /monitoring/summary`

This should replace the current `UnifiedMonitoringService.buildSnapshot()`
aggregation on the client.

Response:

```json
{
  "generated_at": "2026-04-25T10:00:00Z",
  "last_scan_at": "2026-04-25T09:58:00Z",
  "detections": [
    {
      "detection_id": "uuid",
      "platform": "instagram",
      "found_url": "https://instagram.com/...",
      "screenshot_url": "https://cdn.../evidence.jpg",
      "similarity": 0.9132,
      "original_photo_id": "uuid",
      "detected_at": "2026-04-25T10:00:00Z",
      "status": "unread",
      "report_url": "https://help.instagram.com/contact/383679321740945"
    }
  ],
  "generated_notifications": [
    {
      "notification_id": "uuid",
      "type": "danger",
      "message": "Potential impersonation detected on Instagram (91%)",
      "detection_id": "uuid",
      "is_read": false,
      "created_at": "2026-04-25T10:00:00Z"
    }
  ],
  "platforms": [
    {
      "platform": "instagram",
      "is_connected": true,
      "is_demo": false,
      "alert_count": 1
    }
  ]
}
```

#### `GET /scan/status`

Compatible with `ScanStatus.fromJson` in `lib/core/services/scan_service.dart`.

```json
{
  "is_running": true,
  "progress": 60,
  "last_scan_at": "2026-04-25T09:58:00Z",
  "next_scan_at": "2026-04-25T15:00:00Z",
  "current_platform": "instagram",
  "found_count": 3
}
```

#### `POST /scan/start`

Response:

```json
{
  "message": "Scan started",
  "scan_id": "uuid"
}
```

Error cases:

- `409 SCAN_IN_PROGRESS`
- `400 NO_PHOTOS_REGISTERED`

#### `POST /scan/cancel`

Response:

```json
{
  "ok": true
}
```

#### `GET /scan/platforms`

Compatible with `MonitoringPlatform.fromJson`.

```json
{
  "platforms": [
    {
      "id": "instagram",
      "name": "Instagram",
      "icon_url": "https://cdn.../instagram.png",
      "enabled": true,
      "is_official_api": true
    }
  ]
}
```

#### `PATCH /scan/platforms/{platform_id}`

Request:

```json
{
  "enabled": false
}
```

### Reports

#### `POST /reports`

Request:

```json
{
  "detection_id": "uuid"
}
```

Response:

```json
{
  "report_id": "uuid",
  "pdf_url": "https://cdn.../report.pdf",
  "report_url": "https://help.instagram.com/contact/383679321740945"
}
```

Use this to replace the current mock `reportProvider`.

## 5. Celery Job Design

Queue names:

- `scan`
- `match`
- `notify`
- `maintenance`

### Main flow

#### 1. `scan_user_sources(scan_job_id)`

Responsibilities:

- Lock the scan job.
- Load enabled `source_configs`.
- For each enabled source, enqueue `fetch_source_candidates`.
- Update `scan_jobs.current_stage = discover`.

#### 2. `fetch_source_candidates(scan_job_id, source_type)`

Responsibilities:

- Call the provider connector.
- Upsert `candidate_profiles`.
- Upsert `candidate_images`.
- Enqueue `process_candidate_image` for new images.
- Update per-source progress in `scan_jobs.stats`.

#### 3. `process_candidate_image(candidate_image_id, user_id, scan_job_id)`

Responsibilities:

- Download or normalize the image if policy allows.
- Detect faces.
- Reject images with no usable face.
- Create `candidate_embeddings`.
- Enqueue `match_candidate_embedding`.

#### 4. `match_candidate_embedding(candidate_embedding_id, user_id, scan_job_id)`

Responsibilities:

- Load the user centroid and top reference embeddings.
- Compute cosine similarity.
- Apply quality thresholds.
- Apply risk scoring with username/display-name heuristics when available.
- Upsert `detections`.
- If risk is medium/high and not duplicate, enqueue notification.

#### 5. `send_detection_notifications(detection_id)`

Responsibilities:

- Create `notifications` row.
- Send push via FCM if device tokens exist.
- Send email if enabled.
- Mark delivery results.

### Scheduled jobs

#### `schedule_recurring_scans`

- Runs every 4-12 hours depending on plan tier.
- Creates `scan_jobs` for users with active photos and enabled monitoring.

#### `cleanup_candidate_cache`

- Deletes stale candidate images and temporary downloads.
- Retains evidence linked to active detections.

#### `rebuild_reference_centroid(user_id)`

- Runs after photo upload/delete or after a photo is rejected.
- Keeps centroid current for faster matching.

### Retry rules

- Provider/network failures: exponential backoff, max 3 retries
- ML processing failures: max 1 retry unless OOM or corrupted image
- Notification failures: max 5 retries on transient provider errors

## 6. Matching and Risk Policy

Initial rules:

- model: ArcFace via `insightface`
- normalization: L2 normalize every embedding
- similarity metric: cosine similarity
- minimum face size: 112x112 equivalent after alignment
- only use the largest face in profile-avatar contexts for MVP

Initial thresholds:

- `< 0.75`: ignore
- `0.75 - 0.82`: keep as weak evidence only, no alert
- `0.82 - 0.88`: medium risk
- `>= 0.88`: high risk

Risk should not be face-only. Add score bonuses for:

- matching display name
- matching username stem
- repeat hits across sources
- platform account type consistent with impersonation pattern

Risk should be lowered for:

- low-quality or tiny face crop
- multiple unrelated faces in one image
- clear non-profile context

## 7. Flutter Integration Plan For This Exact App

This repo already has the right client structure. Replace the demo mode in four
phases so existing screens stay intact.

### Phase 1: API-backed photos

Files to change:

- `lib/features/photo/providers/photo_provider.dart`
- optionally add `lib/core/services/photo_api_service.dart`

Current behavior:

- returns `MockData.photos`
- keeps uploaded photos only in memory

Target behavior:

- `build()` -> `GET /photos`
- `uploadPhotos()` -> multipart `POST /photos`
- `deletePhoto()` -> `DELETE /photos/{photo_id}`

Keep the current `Photo` model unchanged. The backend response is already shaped
to match it.

### Phase 2: API-backed detections

Files to change:

- `lib/features/detection/providers/detection_provider.dart`
- optionally add `lib/core/services/detection_api_service.dart`

Current behavior:

- reads from `monitoringSnapshotProvider` or `MockData`

Target behavior:

- `detectionsProvider` -> `GET /detections`
- `detectionDetailProvider(id)` -> `GET /detections/{id}`
- add action methods for:
  - mark as read
  - mark false positive
  - mark reported

The current `Detection` model can stay. Add optional `riskLevel` later if the
screen starts surfacing it.

### Phase 3: API-backed dashboard and notifications

Files to change:

- `lib/core/services/unified_monitoring_service.dart`
- `lib/features/notifications/providers/notification_provider.dart`
- `lib/features/dashboard/screens/home_screen.dart`

Current behavior:

- the client assembles a snapshot from mock data plus Meta/Kakao/Naver service stubs

Target behavior:

- `UnifiedMonitoringService.buildSnapshot()` becomes a thin API call to
  `GET /monitoring/summary`
- `notificationsProvider` should call `GET /notifications`
- `markRead()` should call `PATCH /notifications/{id}`

This keeps `HomeScreen` largely unchanged.

### Phase 4: Scan controls and report generation

Files to change:

- `lib/core/services/scan_service.dart`
- `lib/features/report/providers/report_provider.dart`
- `lib/core/services/push_notification_service.dart`

Current behavior:

- `ScanService` already assumes a backend contract
- `reportProvider` is mocked
- push token is never actually registered with a server

Target behavior:

- keep `ScanService` endpoint contract and implement it server-side as specified
- `reportProvider.generate()` -> `POST /reports`
- after FCM token retrieval, call `POST /devices/push-token`

### Integration notes

- `lib/core/services/api_service.dart` is already aligned with a JWT backend.
- `ApiConstants.baseUrl` already points at `https://api.photoshield.kr/v1`.
- The least disruptive migration is to preserve existing JSON field names.
- Keep a fallback demo flag during migration so UI development remains unblocked.

## 8. Suggested JSON Compatibility Rules

To minimize Flutter changes, keep these response contracts exactly:

- `photo_id`
- `thumbnail_url`
- `registered_at`
- `detection_id`
- `found_url`
- `screenshot_url`
- `similarity`
- `original_photo_id`
- `detected_at`
- `notification_id`
- `is_read`
- `created_at`

Do not switch these to camelCase on the backend.

## 9. MVP Build Order

### Backend milestone 1

- user auth
- photo upload
- reference embedding extraction
- photo listing and deletion

### Backend milestone 2

- manual scan trigger
- one connector only: TinEye or Google Vision Web Detection
- candidate processing
- detection creation

### Backend milestone 3

- notifications
- monitoring summary
- report PDF export

### Backend milestone 4

- scheduled scans
- source toggles
- Meta public/business connector
- false-positive feedback loop

## 10. Non-goals For V1

- scraping private accounts
- bypassing platform auth or rate limits
- automated reporting to platforms without approved partner APIs
- supporting every social network equally from day one
- fully automated enforcement without manual review

## 11. Immediate Next Build Step

If implementation starts now, the first backend slice should be:

1. scaffold `backend/`
2. create `users`, `reference_photos`, `reference_embeddings`, `scan_jobs`, and `detections`
3. implement `POST /photos`, `GET /photos`, `POST /scan/start`, `GET /scan/status`, `GET /detections`
4. wire `photo_provider.dart` and `detection_provider.dart`

That gives the current app a real backbone without changing the visible UX.
