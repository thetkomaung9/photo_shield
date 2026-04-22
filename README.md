# PhotoShield Korea

내 사진(SNS 프로필 사진)이 무단 도용되었는지를 AI 가 자동으로 탐지하고 알려주는
Flutter 앱.

## 데모 모드 빠른 시작

이 저장소는 **백엔드(`https://api.photoshield.kr/v1`) 없이도 동작하는 데모 빌드**를
기본 구성으로 가집니다. Flutter 가 설치되어 있으면 다음 한 줄이면 됩니다.

```bash
flutter pub get
flutter run
```

스플래시 화면이 약 2초 동안 표시된 뒤 곧바로 홈 대시보드로 진입하고,
홈 / 감시 / 보호 / 기록 4-탭 네비게이션 안에서 데모 데이터(`MockData`)가
모든 화면을 채웁니다. 어떤 네트워크 연결도 필요하지 않습니다.

## Meta(Facebook + Instagram) 라이브 모드 (선택)

`META_USER_TOKEN` 등 Graph API 자격증명을 컴파일 타임에 주입하면, 감시(Detection)
탭에서 데모 데이터에 라이브 스캔 결과를 추가로 병합해 보여줍니다.

```bash
flutter run \
  --dart-define=META_APP_ID=...        \
  --dart-define=META_APP_TOKEN=...     \
  --dart-define=META_USER_TOKEN=...    \
  --dart-define=META_IG_USER_ID=...    \
  --dart-define=META_MONITOR_TAGS=내사진,프로필도용
```

토큰이 없거나 호출이 실패해도 앱은 그대로 데모 데이터로 동작합니다.

## 디렉터리 구조

```
lib/
├── app.dart
├── main.dart
├── core/
│   ├── constants.dart        # API 상수, MetaEnv (--dart-define)
│   ├── router.dart           # GoRouter + 4-탭 MainShell
│   ├── theme.dart            # 네이비 브랜드 테마
│   └── services/
│       ├── mock_data.dart    # 데모 데이터 single-source-of-truth
│       ├── facebook_api_service.dart
│       ├── instagram_api_service.dart
│       └── ...
├── features/
│   ├── auth/      # 데모 모드는 로그인 화면을 거치지 않음
│   ├── dashboard/ # 홈
│   ├── detection/ # 감시
│   ├── photo/     # 보호 + 사진 등록
│   ├── notifications/ # 기록
│   ├── report/    # 신고하기
│   └── settings/
└── shared/
    ├── models/
    └── widgets/
        └── photoshield_logo.dart
```

자세한 디자인 메모는 [`docs/mockup_observations.md`](docs/mockup_observations.md) 를 참고하세요.
