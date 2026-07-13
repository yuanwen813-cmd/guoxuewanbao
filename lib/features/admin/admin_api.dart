import 'package:dio/dio.dart';

import '../../infrastructure/secure_storage/secure_storage_service.dart';

class AdminApi {
  AdminApi({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? defaultBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 45),
                headers: const {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;

  static const configuredBaseUrl = String.fromEnvironment(
    'GUOXUE_API_BASE_URL',
    defaultValue: '',
  );

  static String get defaultBaseUrl =>
      configuredBaseUrl.isNotEmpty ? configuredBaseUrl : '';

  Future<void> sendCode(String phone) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/admin-auth-send-code',
      data: {'phone': phone},
    );
  }

  Future<Map<String, dynamic>> verifyCode({
    required String phone,
    required String code,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/admin-auth-verify-code',
      data: {
        'phone': phone,
        'code': code,
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> me(String token) {
    return get('/api/admin-me', token: token);
  }

  Future<Map<String, dynamic>> dashboard(String token) {
    return get('/api/admin-dashboard', token: token);
  }

  Future<Map<String, dynamic>> users(
    String token, {
    String? q,
    int page = 1,
    int pageSize = 30,
  }) {
    return get(
      '/api/admin-users',
      token: token,
      query: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  Future<Map<String, dynamic>> userDetail(
    String token, {
    String? userId,
    String? phone,
  }) {
    return get(
      '/api/admin-user-detail',
      token: token,
      query: {
        if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> walletTransactions(
    String token, {
    String? userId,
    int page = 1,
    int pageSize = 30,
  }) {
    return get(
      '/api/admin-wallet-transactions',
      token: token,
      query: {
        if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  Future<Map<String, dynamic>> rechargeOrders(
    String token, {
    String? status,
    String? provider,
    String? outTradeNo,
    int page = 1,
    int pageSize = 30,
  }) {
    return get(
      '/api/admin-recharge-orders',
      token: token,
      query: {
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (provider != null && provider.trim().isNotEmpty)
          'provider': provider.trim(),
        if (outTradeNo != null && outTradeNo.trim().isNotEmpty)
          'outTradeNo': outTradeNo.trim(),
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  Future<Map<String, dynamic>> aiReportOrders(
    String token, {
    String? status,
    String? productId,
    int page = 1,
    int pageSize = 30,
  }) {
    return get(
      '/api/admin-ai-report-orders',
      token: token,
      query: {
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (productId != null && productId.trim().isNotEmpty)
          'productId': productId.trim(),
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  Future<Map<String, dynamic>> aiReportDetail(
    String token, {
    required String orderId,
  }) {
    return get(
      '/api/admin-ai-report-detail',
      token: token,
      query: {'orderId': orderId},
    );
  }

  Future<Map<String, dynamic>> auditLogs(
    String token, {
    String? action,
    String? targetType,
    int page = 1,
    int pageSize = 30,
  }) {
    return get(
      '/api/admin-audit-logs',
      token: token,
      query: {
        if (action != null && action.trim().isNotEmpty) 'action': action.trim(),
        if (targetType != null && targetType.trim().isNotEmpty)
          'targetType': targetType.trim(),
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  Future<Map<String, dynamic>> adjustWallet(
    String token, {
    required String userId,
    required int amountCents,
    required String reason,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/admin-wallet-adjust',
      data: {
        'userId': userId,
        'amountCents': amountCents,
        'reason': reason,
      },
      options: _authOptions(token),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> get(
    String path, {
    required String token,
    Map<String, Object?>? query,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
      options: _authOptions(token),
    );
    return response.data ?? const <String, dynamic>{};
  }

  Options _authOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}

class AdminSessionStore {
  AdminSessionStore._();

  static final AdminSessionStore instance = AdminSessionStore._();
  static const tokenKey = 'guoxueapp.admin.token';

  Future<String?> readToken() {
    return SecureStorageService.instance.read(tokenKey);
  }

  Future<void> saveToken(String token) {
    return SecureStorageService.instance.write(tokenKey, token);
  }

  Future<void> clear() {
    return SecureStorageService.instance.delete(tokenKey);
  }
}

String adminApiError(Object error, [String fallback = '操作失败，请稍后再试']) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return data['error'] as String? ?? data['message'] as String? ?? fallback;
    }
  }
  return fallback;
}
