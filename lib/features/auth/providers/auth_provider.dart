import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 데모 모드 전용 인증 프로바이더.
///
/// 백엔드 인증을 사용하지 않고, 앱 시작과 동시에 항상 인증된 상태로
/// 간주한다. 라우터(`router.dart`) 가 보호된 경로 진입 시 이 상태를
/// 확인하므로, 데모 빌드에서는 로그인/회원가입 화면으로 절대 리다이렉트
/// 되지 않는다.
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  const AuthState({this.isLoading = false, this.isAuthenticated = true});
  AuthState copyWith({bool? isLoading, bool? isAuthenticated}) => AuthState(
        isLoading: isLoading ?? this.isLoading,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isAuthenticated: true));

  /// 앱 시작 시 호출되지만, 데모 모드에서는 항상 인증 상태를 유지한다.
  Future<void> restoreSession() async {
    state = const AuthState(isAuthenticated: true);
  }

  /// 데모 로그인 — 어떤 입력이든 즉시 성공.
  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = const AuthState(isAuthenticated: true);
    return null;
  }

  /// 데모 회원가입 — 어떤 입력이든 즉시 성공.
  Future<String?> signup(String name, String email, String password) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = const AuthState(isAuthenticated: true);
    return null;
  }

  /// 데모 모드에서는 로그아웃해도 다시 인증 상태로 돌아온다.
  Future<void> logout() async {
    state = const AuthState(isAuthenticated: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
