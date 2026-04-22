import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/app_locale.dart';
import 'core/router.dart';
import 'core/theme.dart';

class PhotoShieldApp extends ConsumerWidget {
  const PhotoShieldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: AppLocale.titleFor(locale),
      theme: AppTheme.light,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocale.supportedLocales,
      localizationsDelegates: AppLocale.localizationsDelegates,
      debugShowCheckedModeBanner: false,
    );
  }
}
