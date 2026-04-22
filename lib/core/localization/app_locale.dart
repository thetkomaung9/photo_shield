import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/detection.dart';

const String _localePreferenceKey = 'app_locale_code';

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePreferenceKey, locale.languageCode);
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_localePreferenceKey);
    if (savedCode == 'en' || savedCode == 'ko') {
      state = Locale(savedCode!);
    }
  }
}

class AppLocale {
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ko'),
  ];

  static final List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'appTitle': 'PhotoShield Korea',
      'language': 'Language',
      'english': 'English',
      'korean': 'Korean',
      'notifications': 'Notifications',
      'receivePushNotifications': 'Receive push notifications',
      'automaticPeriodicScan': 'Automatic periodic scan',
      'connectedPlatforms': 'Connected platforms',
      'appInfo': 'App info',
      'version': 'Version',
      'demoMode': 'Demo mode',
      'errorPrefix': 'Error',
      'minutesAgo': '{value}m ago',
      'hoursAgo': '{value}h ago',
      'daysAgo': '{value}d ago',
      'platformInstagram': 'Instagram',
      'platformFacebook': 'Facebook',
      'platformNaverBlog': 'Naver Blog',
      'platformKakaoStory': 'KakaoStory',
      'platformNaver': 'Naver',
      'statusSafe': 'Safe',
      'statusMonitoring': 'Monitoring',
      'statusLearning': 'Learning',
      'splashSubtitle': 'We protect your photos',
      'loginTitle': 'Log In',
      'loginWelcome': 'Welcome to PhotoShield Korea',
      'email': 'Email',
      'password': 'Password',
      'enterValidEmail': 'Please enter a valid email address.',
      'enterPassword': 'Please enter your password.',
      'login': 'Log In',
      'devTestAccount': 'Developer test account',
      'testEmailLabel': 'Email',
      'testPasswordLabel': 'Password',
      'loginWithKakao': 'Continue with Kakao',
      'noAccountSignup': 'No account? Sign up',
      'skip': 'Skip',
      'next': 'Next',
      'getStarted': 'Get Started',
      'alreadyHasAccountLogin': 'Already have an account? Log in',
      'onboardingTitle1': 'Protect your photos',
      'onboardingDesc1':
          'AI monitors Korean SNS and blogs\nautomatically 24/7.',
      'onboardingTitle2': 'Instant misuse alerts',
      'onboardingDesc2':
          'If your photo is found, we notify you\nimmediately with push alerts.',
      'onboardingTitle3': 'One-click reporting support',
      'onboardingDesc3':
          'Automatically generate evidence PDFs\nand support reporting via ECRM.',
      'signupTitle': 'Sign Up',
      'name': 'Name',
      'nameMinLength': 'Name must be at least 2 characters.',
      'passwordMinLength': 'Password must be at least 8 characters.',
      'passwordComplex':
          'Please include letters, numbers, and special characters.',
      'confirmPassword': 'Confirm password',
      'passwordMismatch': 'Passwords do not match.',
      'agreeTerms': 'I agree to the Terms and Privacy Policy',
      'agreeTermsRequired': 'Please agree to the Terms.',
      'signup': 'Sign Up',
      'signupCompleteLogin': 'Sign-up complete. Please log in.',
      'homeNotifTooltip': 'Notifications',
      'homeSettingsTooltip': 'Settings',
      'helloUser': 'Hello, {name}',
      'activityRecords': 'Activity',
      'safeHeadline': 'SAFE',
      'safeDescription':
          'Your photos are currently\nprotected across all platforms',
      'recentScan': 'Last scan: {value}',
      'photoListTitle': 'Protected photos',
      'photoListSummary': 'AI monitors {count} photos for you.',
      'registerPhoto': 'Register photo',
      'photoListEmpty':
          'No photos registered yet.\nAdd a photo to start monitoring.',
      'photoStatusMonitoring': 'Monitoring',
      'photoStatusLearning': 'Training',
      'photoRegistered': 'Photo registered.',
      'photoRegisterTitle': 'Register My Photo',
      'photoRegisterDesc': 'AI learns your face and monitors social platforms.',
      'selectFromGallery': 'Choose from gallery',
      'uploadPhotoPrompt': 'Upload your photo',
      'notificationEmpty': 'No activity records yet.',
      'detectionNoResults': 'No detections found.',
      'previousDetections': 'Previous detections',
      'dangerDetected': 'Danger detected!',
      'unauthorizedUseFound': 'Possible unauthorized use detected',
      'myOriginalPhoto': 'My original photo',
      'fakeInstagramProfile': 'Fake Instagram profile',
      'viewDetails': 'View details',
      'infringementInProgress': 'Impersonation in progress',
      'similarity': 'Similarity',
      'statusUnread': 'Unread',
      'statusRead': 'Read',
      'statusReported': 'Reported',
      'statusFalsePositive': 'False positive',
      'platform': 'Platform',
      'foundUrl': 'Found URL',
      'detectedAt': 'Detected at',
      'report': 'Report',
      'reportTitle': 'Report',
      'reportInstagram': 'Instagram report',
      'reportKakaoStory': 'KakaoStory report',
      'legalGuide': 'Legal response guide',
      'startReportNow': 'Start report now',
      'reportStarted': 'Reporting process started.',
      'noSelectedPhotos': 'No photos selected.',
      'photoLimitExceeded': 'Photo upload limit (5) exceeded.',
      'notifDemo1': 'Potential misuse found on Instagram. (SooYoung_Love)',
      'notifDemo2':
          'Today\'s scheduled scan is complete. No new threats were found.',
      'notifDemo3':
          'Naver Blog misuse report has been submitted and is processing.',
    },
    'ko': {
      'appTitle': '포토쉴드 코리아',
      'language': '언어',
      'english': '영어',
      'korean': '한국어',
      'notifications': '알림',
      'receivePushNotifications': '푸시 알림 받기',
      'automaticPeriodicScan': '자동 정기 검사',
      'connectedPlatforms': '연결된 플랫폼',
      'appInfo': '앱 정보',
      'version': '버전',
      'demoMode': '데모 모드',
      'errorPrefix': '에러',
      'minutesAgo': '{value}분 전',
      'hoursAgo': '{value}시간 전',
      'daysAgo': '{value}일 전',
      'platformInstagram': '인스타그램',
      'platformFacebook': '페이스북',
      'platformNaverBlog': '네이버 블로그',
      'platformKakaoStory': '카카오스토리',
      'platformNaver': '네이버',
      'statusSafe': '안전함',
      'statusMonitoring': '모니터링 중',
      'statusLearning': '학습 중',
      'splashSubtitle': '내 사진을 지켜드립니다',
      'loginTitle': '로그인',
      'loginWelcome': 'PhotoShield Korea에 오신 것을 환영합니다',
      'email': '이메일',
      'password': '비밀번호',
      'enterValidEmail': '올바른 이메일 형식을 입력해 주세요.',
      'enterPassword': '비밀번호를 입력해 주세요.',
      'login': '로그인',
      'devTestAccount': '개발 테스트 계정',
      'testEmailLabel': '이메일',
      'testPasswordLabel': '비밀번호',
      'loginWithKakao': '카카오로 로그인',
      'noAccountSignup': '계정이 없으신가요? 회원가입',
      'skip': '건너뛰기',
      'next': '다음',
      'getStarted': '시작하기',
      'alreadyHasAccountLogin': '이미 계정이 있으신가요? 로그인',
      'onboardingTitle1': '내 사진을 지켜드립니다',
      'onboardingDesc1': 'AI가 24시간 국내 SNS와 블로그를\n자동으로 모니터링합니다.',
      'onboardingTitle2': '도용 즉시 알림',
      'onboardingDesc2': '내 사진이 발견되면 즉시 푸시 알림으로\n알려드립니다.',
      'onboardingTitle3': '원클릭 신고 지원',
      'onboardingDesc3': '증거 PDF를 자동 생성하고\n경찰청 ECRM 신고를 도와드립니다.',
      'signupTitle': '회원가입',
      'name': '이름',
      'nameMinLength': '이름은 2자 이상 입력해 주세요.',
      'passwordMinLength': '비밀번호는 8자 이상이어야 합니다.',
      'passwordComplex': '영문, 숫자, 특수문자를 포함해 주세요.',
      'confirmPassword': '비밀번호 확인',
      'passwordMismatch': '비밀번호가 일치하지 않습니다.',
      'agreeTerms': '이용약관 및 개인정보 처리방침에 동의합니다',
      'agreeTermsRequired': '이용약관에 동의해 주세요.',
      'signup': '가입하기',
      'signupCompleteLogin': '가입이 완료되었습니다. 로그인해 주세요.',
      'homeNotifTooltip': '알림',
      'homeSettingsTooltip': '설정',
      'helloUser': '안녕하세요, {name}님',
      'activityRecords': '활동 기록',
      'safeHeadline': '안전함',
      'safeDescription': '내 사진은 모든 플랫폼에서\n안전하게 보호되고 있습니다',
      'recentScan': '최근 검사: {value}',
      'photoListTitle': '보호 중인 사진',
      'photoListSummary': '총 {count}장의 사진을 AI가 모니터링합니다.',
      'registerPhoto': '사진 등록',
      'photoListEmpty': '아직 등록된 사진이 없습니다.\n사진을 등록하고 모니터링을 시작해 보세요.',
      'photoStatusMonitoring': '모니터링 중',
      'photoStatusLearning': '학습 중',
      'photoRegistered': '사진이 등록되었습니다.',
      'photoRegisterTitle': '내 사진 등록',
      'photoRegisterDesc': 'AI가 당신의 얼굴을 학습하여 SNS를 모니터링합니다.',
      'selectFromGallery': '갤러리에서 선택',
      'uploadPhotoPrompt': '사진을 업로드하세요',
      'notificationEmpty': '아직 활동 기록이 없습니다.',
      'detectionNoResults': '탐지된 결과가 없습니다.',
      'previousDetections': '이전 탐지 기록',
      'dangerDetected': '위험 감지!',
      'unauthorizedUseFound': '무단 도용 의심 사례가 발견되었습니다',
      'myOriginalPhoto': '내 원본 사진',
      'fakeInstagramProfile': '가짜 인스타 프로필',
      'viewDetails': '상세 보기',
      'infringementInProgress': '도용 진행중',
      'similarity': '유사도',
      'statusUnread': '미확인',
      'statusRead': '확인됨',
      'statusReported': '신고완료',
      'statusFalsePositive': '오탐지',
      'platform': '플랫폼',
      'foundUrl': '발견 URL',
      'detectedAt': '탐지 시각',
      'report': '신고하기',
      'reportTitle': '신고하기',
      'reportInstagram': '인스타그램 신고',
      'reportKakaoStory': '카카오스토리 신고',
      'legalGuide': '법적 대응 가이드',
      'startReportNow': '즉시 신고 착수',
      'reportStarted': '신고 절차에 착수했습니다.',
      'noSelectedPhotos': '선택된 사진이 없습니다.',
      'photoLimitExceeded': '사진 등록 한도(5장)를 초과했습니다.',
      'notifDemo1': '인스타그램에서 무단 도용 의심 사례가 발견되었습니다. (SooYoung_Love)',
      'notifDemo2': '오늘의 정기 검사가 완료되었습니다. 새로운 위협은 발견되지 않았습니다.',
      'notifDemo3': '네이버 블로그 도용 신고가 접수되어 처리 중입니다.',
    },
  };

  static String t(BuildContext context, String key) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return _values[languageCode]?[key] ?? _values['en']![key] ?? key;
  }

  static String tf(
    BuildContext context,
    String key,
    Map<String, String> values,
  ) {
    var text = t(context, key);
    values.forEach((k, v) {
      text = text.replaceAll('{$k}', v);
    });
    return text;
  }

  static String titleFor(Locale locale) {
    return _values[locale.languageCode]?['appTitle'] ??
        _values['en']!['appTitle']!;
  }

  static String platform(BuildContext context, String id) => switch (id) {
        'instagram' => t(context, 'platformInstagram'),
        'facebook' => t(context, 'platformFacebook'),
        'naver_blog' => t(context, 'platformNaverBlog'),
        'kakao_story' => t(context, 'platformKakaoStory'),
        'naver' => t(context, 'platformNaver'),
        _ => id,
      };

  static String detectionStatus(BuildContext context, DetectionStatus status) =>
      switch (status) {
        DetectionStatus.unread => t(context, 'statusUnread'),
        DetectionStatus.read => t(context, 'statusRead'),
        DetectionStatus.reported => t(context, 'statusReported'),
        DetectionStatus.falsePositive => t(context, 'statusFalsePositive'),
      };

  static String relativeTime(BuildContext context, DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return tf(context, 'minutesAgo', {'value': diff.inMinutes.toString()});
    }
    if (diff.inHours < 24) {
      return tf(context, 'hoursAgo', {'value': diff.inHours.toString()});
    }
    return tf(context, 'daysAgo', {'value': diff.inDays.toString()});
  }

  static String notificationMessage(
    BuildContext context,
    String notificationId,
    String fallback,
  ) {
    if (notificationId == 'notif_demo_1') {
      return t(context, 'notifDemo1');
    }
    if (notificationId == 'notif_demo_2') {
      return t(context, 'notifDemo2');
    }
    if (notificationId == 'notif_demo_3') {
      return t(context, 'notifDemo3');
    }
    return fallback;
  }

  static String maybeTranslateRaw(BuildContext context, String raw) {
    if (raw == '선택된 사진이 없습니다.' || raw == 'No photos selected.') {
      return t(context, 'noSelectedPhotos');
    }
    if (raw == '사진 등록 한도(5장)를 초과했습니다.' ||
        raw == 'Photo upload limit (5) exceeded.') {
      return t(context, 'photoLimitExceeded');
    }
    return raw;
  }
}

extension AppLocaleX on BuildContext {
  String tr(String key) => AppLocale.t(this, key);

  String trf(String key, Map<String, String> values) =>
      AppLocale.tf(this, key, values);
}
