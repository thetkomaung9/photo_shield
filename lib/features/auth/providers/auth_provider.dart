import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await _storage.write(
        key: StorageKeys.accessToken,
        value: res.data['access_token'],
      );
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return null;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      final code = e.response?.data?['error']?['code'];
      if (code == 'INVALID_CREDENTIALS') return '이메일 또는 비밀번호가 올바르지 않습니다.';
      return '로그인에 실패했습니다. 잠시 후 다시 시도해 주세요.';
    }
  }

  Future<String?> signup(String name, String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      await _dio.post(
        '/auth/signup',
        data: {'name': name, 'email': email, 'password': password},
      );
      state = state.copyWith(isLoading: false);
      return null;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      final code = e.response?.data?['error']?['code'];
      if (code == 'EMAIL_ALREADY_EXISTS') return '이미 가입된 이메일입니다.';
      return '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
    }
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
    await _storage.deleteAll();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
