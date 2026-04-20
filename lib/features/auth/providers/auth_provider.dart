import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─── 개발용 목 인증 (백엔드 서버 없이 테스트) ───────────────────────────
// 서버 연결 후 false 로 변경
const bool _useMockAuth = true;
const _mockEmail = 'test@photoshield.kr';
const _mockPassword = 'Test1234!';
const _mockToken = 'mock_access_token_dev';
// ────────────────────────────────────────────────────────────────────────

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  const AuthState({this.isLoading = false, this.isAuthenticated = false});
  AuthState copyWith({bool? isLoading, bool? isAuthenticated}) => AuthState(
        isLoading: isLoading ?? this.isLoading,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _dio = ApiService().dio;
  final _storage = const FlutterSecureStorage();

  AuthNotifier() : super(const AuthState());

  /// 앱 시작 시 저장된 토큰으로 인증 상태 복원
  Future<void> restoreSession() async {
    try {
      debugPrint('Auth: restoreSession begin');
      final token = await _storage
          .read(key: StorageKeys.accessToken)
          .timeout(const Duration(seconds: 5));
      debugPrint('Auth: restoreSession token exists = ${token != null}');

      state = state.copyWith(isAuthenticated: token != null);
    } catch (e, st) {
      debugPrint('Auth: restoreSession failed - $e');
      debugPrintStack(stackTrace: st);
      state = state.copyWith(isAuthenticated: false);
    }
  }

  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true);

    // 개발용 목 인증
    if (_useMockAuth) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (email == _mockEmail && password == _mockPassword) {
        await _storage.write(key: StorageKeys.accessToken, value: _mockToken);
        state = state.copyWith(isLoading: false, isAuthenticated: true);
        return null;
      } else {
        state = state.copyWith(isLoading: false);
        return '이메일 또는 비밀번호가 올바르지 않습니다.\n(테스트 계정: $_mockEmail / $_mockPassword)';
      }
    }

    try {
      final res = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await _storage.write(
        key: StorageKeys.accessToken,
        value: res.data['access_token'],
      );
      if (res.data['refresh_token'] != null) {
        await _storage.write(
          key: StorageKeys.refreshToken,
          value: res.data['refresh_token'],
        );
      }
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return null;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return '서버에 연결할 수 없습니다. 인터넷 연결을 확인해 주세요.';
      }
      final code = e.response?.data?['error']?['code'];
      if (code == 'INVALID_CREDENTIALS') return '이메일 또는 비밀번호가 올바르지 않습니다.';
      return '로그인에 실패했습니다. 잠시 후 다시 시도해 주세요.';
    }
  }

  Future<String?> signup(String name, String email, String password) async {
    state = state.copyWith(isLoading: true);

    // 개발용 목 회원가입
    if (_useMockAuth) {
      await Future.delayed(const Duration(milliseconds: 800));
      await _storage.write(key: StorageKeys.accessToken, value: _mockToken);
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return null;
    }

    try {
      final res = await _dio.post(
        '/auth/signup',
        data: {'name': name, 'email': email, 'password': password},
      );
      final token = res.data['access_token'];
      if (token != null) {
        await _storage.write(key: StorageKeys.accessToken, value: token);
        if (res.data['refresh_token'] != null) {
          await _storage.write(
            key: StorageKeys.refreshToken,
            value: res.data['refresh_token'],
          );
        }
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return null;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return '서버에 연결할 수 없습니다. 인터넷 연결을 확인해 주세요.';
      }
      final code = e.response?.data?['error']?['code'];
      if (code == 'EMAIL_ALREADY_EXISTS') return '이미 가입된 이메일입니다.';
      return '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
    }
  }

  Future<void> logout() async {
    if (!_useMockAuth) {
      try {
        await _dio.post('/auth/logout');
      } catch (_) {}
    }
    await _storage.deleteAll();
    state = const AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
