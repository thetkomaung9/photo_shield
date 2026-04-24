/// 백엔드/외부 API 공통 상수
class ApiConstants {
  static const String baseUrl = 'https://api.photoshield.kr/v1';
  static const String ecrmUrl = 'https://ecrm.police.go.kr';
  static const String instagramAuthExchangePath = '/social/instagram/exchange';

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

  static String resolveBackendUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }

    final base = Uri.parse(baseUrl);
    final relative = pathOrUrl.startsWith('/')
        ? pathOrUrl.substring(1)
        : pathOrUrl;
    return base.resolve(relative).toString();
  }
}

class SocialCallbackSchemes {
  static const String instagram = 'photoshield-instagram';
  static const String kakao = 'photoshield-kakao';
  static const String naver = 'photoshield-naver';
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
  static const String instagramAccessToken = 'instagram_access_token';
  static const String kakaoAccessToken = 'kakao_access_token';
  static const String naverAccessToken = 'naver_access_token';
  static const String livenessVerifiedAt = 'liveness_verified_at';

  static String socialConnected(String providerId) =>
      'social_connected_$providerId';

  static String socialAccountLabel(String providerId) =>
      'social_account_label_$providerId';

  static String socialConnectedAt(String providerId) =>
      'social_connected_at_$providerId';
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

class InstagramEnv {
  static const String clientId = String.fromEnvironment('INSTAGRAM_CLIENT_ID');
  static const String redirectUri = String.fromEnvironment(
    'INSTAGRAM_REDIRECT_URI',
    defaultValue: '${SocialCallbackSchemes.instagram}://auth',
  );

  static bool get isConfigured => clientId.isNotEmpty && redirectUri.isNotEmpty;
}

class KakaoEnv {
  static const String nativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
  );
  static const String callbackScheme = String.fromEnvironment(
    'KAKAO_CALLBACK_SCHEME',
    defaultValue: SocialCallbackSchemes.kakao,
  );

  static String get redirectUri => '$callbackScheme://oauth';

  static bool get isConfigured => nativeAppKey.isNotEmpty;
}

class NaverEnv {
  static const String clientId = String.fromEnvironment('NAVER_CLIENT_ID');
  static const String clientSecret = String.fromEnvironment(
    'NAVER_CLIENT_SECRET',
  );
  static const String serviceName = String.fromEnvironment(
    'NAVER_SERVICE_NAME',
  );
  static const String redirectUri = String.fromEnvironment(
    'NAVER_REDIRECT_URI',
    defaultValue: '${SocialCallbackSchemes.naver}://auth',
  );

  static bool get isConfigured =>
      clientId.isNotEmpty && clientSecret.isNotEmpty && redirectUri.isNotEmpty;
}

class MonitoringEnv {
  static const String keywords = String.fromEnvironment(
    'MONITOR_KEYWORDS',
    defaultValue: '내사진,프로필도용,무단도용',
  );
  static const String facebookSuspectPages = String.fromEnvironment(
    'FACEBOOK_SUSPECT_PAGE_IDS',
    defaultValue: '',
  );
  static const String kakaoEndpoint = String.fromEnvironment(
    'KAKAO_MONITOR_ENDPOINT',
    defaultValue: '/monitoring/kakao/detections',
  );
  static const String naverEndpoint = String.fromEnvironment(
    'NAVER_MONITOR_ENDPOINT',
    defaultValue: '/monitoring/naver/detections',
  );
}
