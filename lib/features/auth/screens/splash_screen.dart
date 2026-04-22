import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/photoshield_logo.dart';

/// 데모 모드 스플래시.
///
/// 짙은 네이비 배경 + 가운데 방패 + 카메라 렌즈 로고 + 한국어 타이포.
/// 약 2초 후 무조건 `/home` 으로 진입한다 — 로그인/온보딩은 표시하지 않는다.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _go());
  }

  Future<void> _go() async {
    if (_navigated) return;
    _navigated = true;
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              PhotoShieldLogoMark(
                size: 160,
                shieldColor: Colors.white,
                lensColor: Color(0xFF1E3A8A),
              ),
              SizedBox(height: 32),
              Text(
                '포토쉴드 코리아',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '내 사진을 지켜드립니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
