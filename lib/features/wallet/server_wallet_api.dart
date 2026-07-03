import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'wallet_store.dart';

typedef AuthTokenProvider = Future<String?> Function();

class ServerWalletApi {
  final Dio _dio;
  final AuthTokenProvider? _tokenProvider;

  ServerWalletApi({
    Dio? dio,
    String? baseUrl,
    AuthTokenProvider? tokenProvider,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? _defaultBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 120),
                headers: const {'Content-Type': 'application/json'},
              ),
            ),
        _tokenProvider = tokenProvider;

  static const _configuredBaseUrl = String.fromEnvironment(
    'GUOXUE_API_BASE_URL',
    defaultValue: '',
  );

  static String get _defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    return kIsWeb ? '' : 'http://127.0.0.1:8080';
  }

  Future<WalletState> fetchWallet() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/wallet',
        options: await _authOptions(),
      );
      return _walletFromResponse(response.data);
    } on DioException catch (error) {
      throw ServerWalletException.fromDio(error);
    }
  }

  Future<List<WalletTransaction>> fetchTransactions({
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/wallet-transactions',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
        options: await _authOptions(),
      );
      final data = response.data ?? const <String, dynamic>{};
      final tx = data['transactions'];
      return tx is List
          ? tx
              .map((item) =>
                  WalletTransaction.fromJson(item as Map<String, dynamic>))
              .toList()
          : const [];
    } on DioException catch (error) {
      throw ServerWalletException.fromDio(error);
    }
  }

  Future<RechargeCreateResult> createRecharge({
    required int amountCents,
    required String provider,
    required String tradeType,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/recharge-create',
        data: {
          'provider': provider,
          'tradeType': tradeType,
          'amountCents': amountCents,
        },
        options: await _authOptions(),
      );
      final data = response.data ?? const <String, dynamic>{};
      return RechargeCreateResult.fromJson(data);
    } on DioException catch (error) {
      throw ServerWalletException.fromDio(error);
    }
  }

  Future<RechargeOrder> fetchRechargeStatus({
    String? orderId,
    String? outTradeNo,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/recharge-status',
        queryParameters: {
          if (orderId != null) 'orderId': orderId,
          if (outTradeNo != null) 'outTradeNo': outTradeNo,
        },
        options: await _authOptions(),
      );
      final data = response.data ?? const <String, dynamic>{};
      return RechargeOrder.fromJson(
        data['order'] as Map<String, dynamic>? ?? const {},
      );
    } on DioException catch (error) {
      throw ServerWalletException.fromDio(error);
    }
  }

  Future<RechargeOrder> cancelRecharge({
    String? orderId,
    String? outTradeNo,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/recharge-cancel',
        data: {
          if (orderId != null) 'orderId': orderId,
          if (outTradeNo != null) 'outTradeNo': outTradeNo,
        },
        options: await _authOptions(),
      );
      final data = response.data ?? const <String, dynamic>{};
      return RechargeOrder.fromJson(
        data['order'] as Map<String, dynamic>? ?? const {},
      );
    } on DioException catch (error) {
      throw ServerWalletException.fromDio(error);
    }
  }

  Future<ServerAiReportResult> generateAiReport({
    required String productId,
    required String featureKey,
    required String title,
    required String systemPrompt,
    required String userPrompt,
    required double temperature,
    String? sourceJson,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/ai-report-generate',
        data: {
          'productId': productId,
          'featureKey': featureKey,
          'title': title,
          'systemPrompt': systemPrompt,
          'userPrompt': userPrompt,
          'temperature': temperature,
          'questionResultJson': _tryDecodeJson(sourceJson),
        },
        options: await _authOptions(),
      );
      final data = response.data ?? const <String, dynamic>{};
      return ServerAiReportResult(
        answer: data['answer'] as String? ?? '',
        model: data['model'] as String? ?? '',
        reportId: (data['report'] as Map<String, dynamic>?)?['id'] as String?,
        wallet: _walletFromResponse(data),
      );
    } on DioException catch (error) {
      final wallet = _maybeWalletFromResponse(error.response?.data);
      throw ServerWalletException.fromDio(error, wallet: wallet);
    }
  }

  Future<Options> _authOptions() async {
    final token = await _tokenProvider?.call();
    if (token == null || token.isEmpty) {
      return Options();
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Object _tryDecodeJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <String, dynamic>{};
    try {
      return jsonDecode(raw);
    } catch (_) {
      return {'raw': raw};
    }
  }

  WalletState _walletFromResponse(Map<String, dynamic>? data) {
    final wallet = data?['wallet'];
    if (wallet is Map<String, dynamic>) {
      return WalletState.fromJson(wallet);
    }
    return const WalletState();
  }

  WalletState? _maybeWalletFromResponse(Object? data) {
    if (data is Map<String, dynamic> &&
        data['wallet'] is Map<String, dynamic>) {
      return WalletState.fromJson(data['wallet'] as Map<String, dynamic>);
    }
    return null;
  }
}

class ServerAiReportResult {
  final String answer;
  final String model;
  final String? reportId;
  final WalletState wallet;

  const ServerAiReportResult({
    required this.answer,
    required this.model,
    required this.wallet,
    this.reportId,
  });
}

class RechargeCreateResult {
  final RechargeOrder order;
  final RechargePayment payment;
  final WalletState wallet;

  const RechargeCreateResult({
    required this.order,
    required this.payment,
    required this.wallet,
  });

  factory RechargeCreateResult.fromJson(Map<String, dynamic> json) {
    return RechargeCreateResult(
      order: RechargeOrder.fromJson(
        json['order'] as Map<String, dynamic>? ?? const {},
      ),
      payment: RechargePayment.fromJson(
        json['payment'] as Map<String, dynamic>? ?? const {},
      ),
      wallet: WalletState.fromJson(
        json['wallet'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class RechargeOrder {
  final String id;
  final String outTradeNo;
  final String provider;
  final String tradeType;
  final int amountCents;
  final String status;

  const RechargeOrder({
    required this.id,
    required this.outTradeNo,
    required this.provider,
    required this.tradeType,
    required this.amountCents,
    required this.status,
  });

  factory RechargeOrder.fromJson(Map<String, dynamic> json) {
    return RechargeOrder(
      id: json['id'] as String? ?? '',
      outTradeNo: json['outTradeNo'] as String? ??
          json['out_trade_no'] as String? ??
          '',
      provider: json['provider'] as String? ?? '',
      tradeType:
          json['tradeType'] as String? ?? json['trade_type'] as String? ?? '',
      amountCents: json['amountCents'] as int? ??
          int.tryParse('${json['amount_cents']}') ??
          0,
      status: json['status'] as String? ?? '',
    );
  }
}

class RechargePayment {
  final String provider;
  final String tradeType;
  final bool paymentReady;
  final String? codeUrl;
  final String? payUrl;
  final String? message;

  const RechargePayment({
    required this.provider,
    required this.tradeType,
    required this.paymentReady,
    this.codeUrl,
    this.payUrl,
    this.message,
  });

  factory RechargePayment.fromJson(Map<String, dynamic> json) {
    return RechargePayment(
      provider: json['provider'] as String? ?? '',
      tradeType:
          json['tradeType'] as String? ?? json['trade_type'] as String? ?? '',
      paymentReady: json['paymentReady'] as bool? ?? false,
      codeUrl: json['codeUrl'] as String? ?? json['code_url'] as String?,
      payUrl: json['payUrl'] as String? ?? json['pay_url'] as String?,
      message: json['message'] as String?,
    );
  }
}

class ServerWalletException implements Exception {
  final String message;
  final int? statusCode;
  final WalletState? wallet;

  const ServerWalletException(
    this.message, {
    this.statusCode,
    this.wallet,
  });

  factory ServerWalletException.fromDio(
    DioException error, {
    WalletState? wallet,
  }) {
    final data = error.response?.data;
    final message = data is Map<String, dynamic>
        ? data['error'] as String? ?? data['message'] as String?
        : null;
    return ServerWalletException(
      message ?? '服务端暂时不可用，请稍后再试',
      statusCode: error.response?.statusCode,
      wallet: wallet,
    );
  }

  @override
  String toString() => message;
}
