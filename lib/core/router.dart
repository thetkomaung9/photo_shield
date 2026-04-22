import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/dashboard/screens/home_screen.dart';
import '../features/detection/screens/detection_detail_screen.dart';
import '../features/detection/screens/detection_list_screen.dart';
import '../features/notifications/screens/notification_screen.dart';
import '../features/photo/screens/photo_list_screen.dart';
import '../features/photo/screens/photo_register_screen.dart';
import '../features/report/screens/report_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import 'theme.dart';

/// 데모 모드 라우터 — 인증 게이팅 없이 모든 화면 자유 진입.
///
/// 메인 4-탭(`/home`, `/monitor`, `/protect`, `/records`) 은 [MainShell] 안에서
/// 공유된 하단 네비게이션 바를 사용한다. 로그인/온보딩 화면은 라우트로는
/// 남겨 두지만 스플래시는 항상 `/home` 으로 이동한다.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/monitor',
            builder: (_, __) => const DetectionListScreen(),
          ),
          GoRoute(
            path: '/protect',
            builder: (_, __) => const PhotoListScreen(),
          ),
          GoRoute(
            path: '/records',
            builder: (_, __) => const NotificationScreen(),
          ),
          GoRoute(
            path: '/photos/register',
            builder: (_, __) => const PhotoRegisterScreen(),
          ),
          GoRoute(
            path: '/detections/:id',
            builder: (_, state) =>
                DetectionDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/detections/:id/report',
            builder: (_, state) =>
                ReportScreen(detectionId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/report',
            builder: (_, __) => const ReportScreen(detectionId: 'detection_demo_1'),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

/// 메인 4-탭 컨테이너.
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = <_TabSpec>[
    _TabSpec(route: '/home', icon: Icons.home_rounded, label: '홈'),
    _TabSpec(route: '/monitor', icon: Icons.search_rounded, label: '감시'),
    _TabSpec(route: '/protect', icon: Icons.shield_rounded, label: '보호'),
    _TabSpec(route: '/records', icon: Icons.list_alt_rounded, label: '기록'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 70,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final spec = _tabs[i];
                final selected = i == index;
                return Expanded(
                  child: InkWell(
                    onTap: () => context.go(spec.route),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          spec.icon,
                          color: selected
                              ? AppTheme.primary
                              : Colors.grey.shade500,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          spec.label,
                          style: TextStyle(
                            color: selected
                                ? AppTheme.primary
                                : Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/monitor') ||
        location.startsWith('/detections')) {
      return 1;
    }
    if (location.startsWith('/protect') || location.startsWith('/photos')) {
      return 2;
    }
    if (location.startsWith('/records') ||
        location.startsWith('/notifications') ||
        location.startsWith('/report')) {
      return 3;
    }
    return 0;
  }
}

class _TabSpec {
  final String route;
  final IconData icon;
  final String label;
  const _TabSpec({
    required this.route,
    required this.icon,
    required this.label,
  });
}
