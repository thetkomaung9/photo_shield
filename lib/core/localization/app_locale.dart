import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      state = Locale(savedCode);
    }
  }
}

class AppLocale {
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ko'),
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
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
    },
  };

  static String t(BuildContext context, String key) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return _values[languageCode]?[key] ?? _values['en']![key] ?? key;
  }

  static String titleFor(Locale locale) {
    return _values[locale.languageCode]?['appTitle'] ??
        _values['en']!['appTitle']!;
  }
}

extension AppLocaleX on BuildContext {
  String tr(String key) => AppLocale.t(this, key);
}