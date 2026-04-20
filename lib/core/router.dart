import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/dashboard/screens/home_screen.dart';
import '../features/photo/screens/photo_list_screen.dart';
import '../features/photo/screens/photo_register_screen.dart';
import '../features/detection/screens/detection_list_screen.dart';
import '../features/detection/screens/detection_detail_screen.dart';
import '../features/report/screens/report_screen.dart';
import '../features/notifications/screens/notification_screen.dart';
import '../features/settings/screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final location = state.matchedLocation;

      // Skip redirect on splash - let it handle its own navigation
      if (location == '/') return null;

      // 보호된 경로 목록
      final protectedPaths = [
        '/home',
        '/photos',
        '/detections',
        '/notifications',
        '/settings',
      ];
      final isProtected = protectedPaths.any((p) => location.startsWith(p));

      if (isProtected && !isAuthenticated) return '/login';
      return null;
    },
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
          GoRoute(path: '/photos', builder: (_, __) => const PhotoListScreen()),
          GoRoute(
            path: '/photos/register',
            builder: (_, __) => const PhotoRegisterScreen(),
          ),
          GoRoute(
            path: '/detections',
            builder: (_, __) => const DetectionListScreen(),
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

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => _navigate(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_outlined),
            selectedIcon: Icon(Icons.photo),
            label: '사진',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '탐지결과',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: '알림',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/photos')) return 1;
    if (location.startsWith('/detections')) return 2;
    if (location.startsWith('/notifications')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    const routes = [
      '/home',
      '/photos',
      '/detections',
      '/notifications',
      '/settings',
    ];
    context.go(routes[index]);
  }
}
