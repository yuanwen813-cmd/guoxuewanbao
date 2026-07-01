import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/secure_storage/secure_storage_service.dart';

final authStoreProvider = StateNotifierProvider<AuthStore, AuthState>(
  (ref) => AuthStore(),
);

class AppUser {
  final String id;
  final String? phone;
  final String? nickname;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    this.phone,
    this.nickname,
    this.avatarUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      phone: json['phone'] as String?,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
    );
  }
}

class AuthState {
  final bool initialized;
  final bool loading;
  final String? token;
  final AppUser? user;
  final String? message;
  final String? error;

  const AuthState({
    this.initialized = false,
    this.loading = false,
    this.token,
    this.user,
    this.message,
    this.error,
  });

  bool get isAuthenticated =>
      token != null && token!.isNotEmpty && user != null;

  AuthState copyWith({
    bool? initialized,
    bool? loading,
    String? token,
    AppUser? user,
    String? message,
    String? error,
    bool clearToken = false,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
      token: clearToken ? null : token ?? this.token,
      user: clearToken ? null : user ?? this.user,
      message: clearMessage ? null : message ?? this.message,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AuthApi {
  final Dio _dio;

  AuthApi({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? defaultBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: const {'Content-Type': 'application/json'},
              ),
            );

  static const configuredBaseUrl = String.fromEnvironment(
    'GUOXUE_API_BASE_URL',
    defaultValue: '',
  );

  static String get defaultBaseUrl =>
      configuredBaseUrl.isNotEmpty ? configuredBaseUrl : '';

  Future<void> sendCode(String phone) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/auth-send-code',
      data: {'phone': phone},
    );
  }

  Future<({String token, AppUser user})> verifyCode({
    required String phone,
    required String code,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth-verify-code',
      data: {
        'phone': phone,
        'code': code,
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    return (
      token: data['token'] as String? ?? '',
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Future<AppUser> me(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/auth-me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = response.data ?? const <String, dynamic>{};
    return AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
  }
}

class AuthStore extends StateNotifier<AuthState> {
  final AuthApi _api;
  final SecureStorageService _storage;

  AuthStore({
    AuthApi? api,
    SecureStorageService? storage,
    AuthState? initialState,
  })  : _api = api ?? AuthApi(),
        _storage = storage ?? SecureStorageService.instance,
        super(initialState ?? const AuthState(loading: true)) {
    if (initialState == null) _load();
  }

  static const _tokenKey = 'guoxueapp.auth.token';

  Future<void> _load() async {
    try {
      final token = await _storage.read(_tokenKey);
      if (token == null || token.isEmpty) {
        state = const AuthState(initialized: true);
        return;
      }
      final user = await _api.me(token);
      state = AuthState(
        initialized: true,
        token: token,
        user: user,
      );
    } catch (_) {
      await _storage.delete(_tokenKey);
      state = const AuthState(
        initialized: true,
        error: '登录状态已失效，请重新登录',
      );
    }
  }

  Future<void> sendCode(String phone) async {
    state = state.copyWith(
      loading: true,
      clearError: true,
      clearMessage: true,
    );
    try {
      await _api.sendCode(phone);
      state = state.copyWith(
        loading: false,
        initialized: true,
        message: '验证码已发送，请查收短信',
      );
    } on DioException catch (error) {
      state = state.copyWith(
        loading: false,
        initialized: true,
        error: _messageFromDio(error, '验证码发送失败，请稍后再试'),
      );
    }
  }

  Future<void> verifyCode({
    required String phone,
    required String code,
  }) async {
    state = state.copyWith(
      loading: true,
      clearError: true,
      clearMessage: true,
    );
    try {
      final result = await _api.verifyCode(phone: phone, code: code);
      await _storage.write(_tokenKey, result.token);
      state = AuthState(
        initialized: true,
        token: result.token,
        user: result.user,
        message: '登录成功',
      );
    } on DioException catch (error) {
      state = state.copyWith(
        loading: false,
        initialized: true,
        error: _messageFromDio(error, '登录失败，请检查验证码'),
      );
    }
  }

  Future<void> logout() async {
    await _storage.delete(_tokenKey);
    state = const AuthState(initialized: true, message: '已退出登录');
  }

  String _messageFromDio(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return data['error'] as String? ?? data['message'] as String? ?? fallback;
    }
    return fallback;
  }
}
