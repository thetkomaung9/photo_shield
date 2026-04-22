/// 백엔드/외부 API 공통 상수
class ApiConstants {
  static const String baseUrl = 'https://api.photoshield.kr/v1';
  static const String ecrmUrl = 'https://ecrm.police.go.kr';

  /// Meta Graph API
  ///
  /// graph.facebook.com 은 Facebook + (Facebook Login 기반) Instagram API,
  /// graph.instagram.com 은 Instagram Login 기반 Direct API 에 사용된다.
  static const String metaGraphApiVersion = 'v22.0';
  static const String facebookGraphBaseUrl =
      'https://graph.facebook.com/$metaGraphApiVersion';
  static const String instagramGraphBaseUrl =
      'https://graph.instagram.com/$metaGraphApiVersion';

  /// 사용자가 신고를 시작할 수 있는 공식 페이지
  static const String facebookReportUrl =
      'https://www.facebook.com/help/contact/144059062408922';
  static const String instagramReportUrl =
      'https://help.instagram.com/contact/383679321740945';
}

/// SecureStorage 키
class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';

  /// Meta API 토큰들 (런타임에 사용자가 설정 화면에서 입력했을 때를 대비)
  static const String metaUserToken = 'meta_user_token';
  static const String metaAppToken = 'meta_app_token';
  static const String metaIgUserId = 'meta_ig_user_id';
}

/// `--dart-define` 으로 컴파일 타임에 주입되는 환경 변수.
///
/// 셋 중 어느 하나라도 비어 있으면 해당 서비스는 데모(목업) 모드로 동작한다.
class MetaEnv {
  /// Meta 앱의 숫자 App ID
  static const String appId = String.fromEnvironment('META_APP_ID');

  /// `{app_id}|{app_secret}` 형식의 앱 액세스 토큰. oEmbed 류 호출에 사용.
  static const String appToken = String.fromEnvironment('META_APP_TOKEN');

  /// 장기 사용자 액세스 토큰 (Instagram 비즈니스/크리에이터 계정과 연결됨).
  static const String userToken = String.fromEnvironment('META_USER_TOKEN');

  /// 연결된 Instagram 비즈니스 계정의 IG User ID.
  /// 미설정 시 `/me` 호출로 자동 조회한다.
  static const String igUserId = String.fromEnvironment('META_IG_USER_ID');

  /// 모니터링 대상 키워드/해시태그 (콤마 구분).
  /// 예: `--dart-define=META_MONITOR_TAGS=내사진,프로필도용`
  static const String monitorTags = String.fromEnvironment(
    'META_MONITOR_TAGS',
    defaultValue: '',
  );
}
