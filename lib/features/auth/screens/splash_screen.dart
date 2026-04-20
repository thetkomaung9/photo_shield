import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigate();
    });
  }

  Future<void> _navigate() async {
    if (_navigating) return;
    _navigating = true;

    try {
      debugPrint('Splash: startup begin');
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('Splash: delay complete');

      if (!mounted) return;

      await ref
          .read(authProvider.notifier)
          .restoreSession()
          .timeout(const Duration(seconds: 5));

      debugPrint('Splash: session restore complete');

      if (!mounted) return;

      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      debugPrint(
          'Splash: navigating to ${isAuthenticated ? '/home' : '/onboarding'}');
      context.go(isAuthenticated ? '/home' : '/onboarding');
    } catch (e, st) {
      debugPrint('Splash: startup failed - $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.shield,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'PhotoShield Korea',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '내 사진을 지켜드립니다',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
