import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/push_notification_service.dart';
import '../../../core/services/social_auth_service.dart';
import '../../../core/services/mock_data.dart';
import '../../../shared/models/social_connection.dart';
import '../../../shared/models/social_platform.dart';

/// 데모 모드 전용 인증 프로바이더.
///
/// 백엔드 인증을 사용하지 않고, 앱 시작과 동시에 항상 인증된 상태로
/// 간주한다. 라우터(`router.dart`) 가 보호된 경로 진입 시 이 상태를
/// 확인하므로, 데모 빌드에서는 로그인/회원가입 화면으로 절대 리다이렉트
/// 되지 않는다.
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String displayName;
  final String email;
  final SocialPlatform? lastLoginPlatform;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = true,
    this.displayName = '사용자',
    this.email = 'user@photoshield.kr',
    this.lastLoginPlatform,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? displayName,
    String? email,
    SocialPlatform? lastLoginPlatform,
    bool clearLastLoginPlatform = false,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        lastLoginPlatform: clearLastLoginPlatform
            ? null
            : (lastLoginPlatform ?? this.lastLoginPlatform),
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required this.ref,
    required SocialAuthService socialAuthService,
    required PushNotificationService pushNotificationService,
  })  : _socialAuthService = socialAuthService,
        _pushNotificationService = pushNotificationService,
        super(
          AuthState(
            isAuthenticated: true,
            displayName: MockData.currentUser.name,
            email: MockData.currentUser.email,
          ),
        );

  final Ref ref;
  final SocialAuthService _socialAuthService;
  final PushNotificationService _pushNotificationService;

  /// 앱 시작 시 호출되지만, 데모 모드에서는 항상 인증 상태를 유지한다.
  Future<void> restoreSession() async {
    state = AuthState(
      isAuthenticated: true,
      displayName: MockData.currentUser.name,
      email: MockData.currentUser.email,
    );
  }

  /// 데모 로그인 — 어떤 입력이든 즉시 성공.
  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      displayName: MockData.currentUser.name,
      email: email,
      clearLastLoginPlatform: true,
    );
    return null;
  }

  /// 데모 회원가입 — 어떤 입력이든 즉시 성공.
  Future<String?> signup(String name, String email, String password) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      displayName: name,
      email: email,
      clearLastLoginPlatform: true,
    );
    return null;
  }

  Future<SocialConnection?> loginWithSocial(SocialPlatform platform) async {
    state = state.copyWith(isLoading: true);
    try {
      final connection = await _socialAuthService.connect(platform);
      await _pushNotificationService.subscribeToTopic('monitoring_alerts');
      await _pushNotificationService.subscribeToTopic(platform.pushTopic);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        displayName: connection.accountLabel ?? state.displayName,
        email: '${platform.id}@photoshield.local',
        lastLoginPlatform: platform,
      );
      ref.invalidate(socialConnectionsProvider);
      return connection;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return null;
    }
  }

  /// 데모 모드에서는 로그아웃해도 다시 인증 상태로 돌아온다.
  Future<void> logout() async {
    state = AuthState(
      isAuthenticated: true,
      displayName: MockData.currentUser.name,
      email: MockData.currentUser.email,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref: ref,
    socialAuthService: ref.watch(socialAuthServiceProvider),
    pushNotificationService: ref.watch(pushNotificationServiceProvider),
  ),
);
