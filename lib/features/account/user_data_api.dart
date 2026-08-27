import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class UserDataApi {
  UserDataApi({Dio? dio, String? baseUrl})
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

  static String get defaultBaseUrl {
    if (configuredBaseUrl.isNotEmpty) return configuredBaseUrl;
    return kIsWeb ? '' : 'http://127.0.0.1:8080';
  }

  Options _auth(String token) => Options(
        headers: {'Authorization': 'Bearer $token'},
      );

  Future<UserCloudData> fetch(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/user-data',
      options: _auth(token),
    );
    return UserCloudData.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<UserCloudData> sync(
    String token, {
    List<Map<String, dynamic>> histories = const [],
    List<Map<String, dynamic>> profiles = const [],
    List<String> deletedHistoryIds = const [],
    List<String> deletedProfileIds = const [],
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/user-data',
      data: {
        'histories': histories,
        'profiles': profiles,
        'deletedHistoryIds': deletedHistoryIds,
        'deletedProfileIds': deletedProfileIds,
      },
      options: _auth(token),
    );
    return UserCloudData.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<Map<String, dynamic>> exportAccount(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/account-export',
      options: _auth(token),
    );
    return response.data?['data'] as Map<String, dynamic>? ?? const {};
  }

  Future<void> deleteAccount(String token, String confirmation) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/account-delete',
      data: {'confirmation': confirmation},
      options: _auth(token),
    );
  }

  Future<void> submitAiFeedback(
    String token, {
    required String reportId,
    required String rating,
    String? reason,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/ai-report-feedback',
      data: {
        'reportId': reportId,
        'rating': rating,
        if (reason?.trim().isNotEmpty == true) 'reason': reason!.trim(),
      },
      options: _auth(token),
    );
  }

  Future<void> recordAttribution(
    String token, {
    required String source,
    String? medium,
    String? campaign,
    String? referrer,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/attribution-record',
      data: {
        'source': source,
        if (medium?.isNotEmpty == true) 'medium': medium,
        if (campaign?.isNotEmpty == true) 'campaign': campaign,
        if (referrer?.isNotEmpty == true) 'referrer': referrer,
      },
      options: _auth(token),
    );
  }
}

class UserCloudData {
  const UserCloudData({
    this.histories = const [],
    this.profiles = const [],
    this.syncedAt,
  });

  final List<Map<String, dynamic>> histories;
  final List<Map<String, dynamic>> profiles;
  final DateTime? syncedAt;

  factory UserCloudData.fromJson(Map<String, dynamic> json) {
    return UserCloudData(
      histories: _mapList(json['histories']),
      profiles: _mapList(json['profiles']),
      syncedAt: DateTime.tryParse(json['syncedAt'] as String? ?? ''),
    );
  }

  static List<Map<String, dynamic>> _mapList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

String userDataApiMessage(Object error, [String fallback = '操作失败，请稍后再试']) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return data['error'] as String? ?? data['message'] as String? ?? fallback;
    }
  }
  return fallback;
}
