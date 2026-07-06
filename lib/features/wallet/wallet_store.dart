import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/local_persistence/local_json_store.dart';
import '../auth/auth_store.dart';
import 'server_wallet_api.dart';

final walletStoreProvider = StateNotifierProvider<WalletStore, WalletState>(
  (ref) => WalletStore(
    api: ServerWalletApi(
      tokenProvider: () async => ref.read(authStoreProvider).token,
    ),
  ),
);

class WalletState {
  final int balanceCents;
  final String currency;
  final String? updatedAt;
  final List<WalletTransaction> transactions;

  const WalletState({
    this.balanceCents = 0,
    this.currency = 'CNY',
    this.updatedAt,
    this.transactions = const [],
  });

  WalletState copyWith({
    int? balanceCents,
    String? currency,
    String? updatedAt,
    List<WalletTransaction>? transactions,
  }) {
    return WalletState(
      balanceCents: balanceCents ?? this.balanceCents,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
      transactions: transactions ?? this.transactions,
    );
  }

  Map<String, dynamic> toJson() => {
        'balanceCents': balanceCents,
        'currency': currency,
        'updatedAt': updatedAt,
        'transactions': transactions.map((item) => item.toJson()).toList(),
      };

  factory WalletState.fromJson(Map<String, dynamic> json) {
    final tx = json['transactions'];
    return WalletState(
      balanceCents: json['balanceCents'] as int? ??
          int.tryParse('${json['balance_cents']}') ??
          0,
      currency: json['currency'] as String? ?? 'CNY',
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String?,
      transactions: tx is List
          ? tx
              .map((item) =>
                  WalletTransaction.fromJson(item as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}

class WalletTransaction {
  final String id;
  final WalletTransactionType type;
  final int amountCents;
  final String title;
  final String? featureKey;
  final String? productId;
  final String? relatedTransactionId;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.title,
    required this.createdAt,
    this.featureKey,
    this.productId,
    this.relatedTransactionId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amountCents': amountCents,
        'title': title,
        'featureKey': featureKey,
        'productId': productId,
        'relatedTransactionId': relatedTransactionId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final type = _typeFromJson(json['type'] as String?);
    return WalletTransaction(
      id: json['id'] as String? ?? '',
      type: type,
      amountCents: json['amountCents'] as int? ??
          int.tryParse('${json['amount_cents']}') ??
          0,
      title: json['title'] as String? ??
          json['note'] as String? ??
          _defaultTitle(type),
      featureKey: json['featureKey'] as String?,
      productId: json['productId'] as String?,
      relatedTransactionId: json['relatedTransactionId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static WalletTransactionType _typeFromJson(String? rawType) {
    return switch (rawType) {
      'recharge' => WalletTransactionType.recharge,
      'ai_debit' => WalletTransactionType.aiDebit,
      'ai_refund' => WalletTransactionType.aiRefund,
      'manual_adjust' => WalletTransactionType.manualAdjust,
      'refund' => WalletTransactionType.refund,
      _ => WalletTransactionType.charge,
    };
  }

  static String _defaultTitle(WalletTransactionType type) {
    return switch (type) {
      WalletTransactionType.recharge => '余额充值',
      WalletTransactionType.aiDebit => 'AI 解析扣费',
      WalletTransactionType.aiRefund => 'AI 失败退款',
      WalletTransactionType.manualAdjust => '余额调整',
      WalletTransactionType.refund => '退款',
      WalletTransactionType.charge => '消费',
    };
  }
}

enum WalletTransactionType {
  recharge,
  charge,
  refund,
  aiDebit,
  aiRefund,
  manualAdjust,
}

class WalletChargeResult {
  final bool success;
  final String message;
  final String? transactionId;

  const WalletChargeResult({
    required this.success,
    required this.message,
    this.transactionId,
  });
}

class WalletStore extends StateNotifier<WalletState> {
  final ServerWalletApi? _api;

  WalletStore({
    ServerWalletApi? api,
    bool useServer = true,
  })  : _api = useServer ? (api ?? ServerWalletApi()) : null,
        super(const WalletState()) {
    _load();
  }

  static const _storageKey = 'guoxueapp.wallet.v1';

  Future<void> rechargeYuan(int yuan) async {
    if (yuan < 1) {
      throw ArgumentError('充值金额不能低于 1 元');
    }
    if (_api != null) {
      final result = await createRecharge(
        amountCents: yuan * 100,
        provider: 'wechat',
        tradeType: 'web_native',
      );
      state = result.wallet;
      await _persist();
      return;
    }
    await _append(
      WalletTransaction(
        id: _newId('recharge'),
        type: WalletTransactionType.recharge,
        amountCents: yuan * 100,
        title: '本地测试充值',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> syncFromServer() async {
    if (_api == null) return;
    state = await _api.fetchWallet();
    await _persist();
  }

  Future<RechargeCreateResult> createRecharge({
    required int amountCents,
    required String provider,
    required String tradeType,
  }) async {
    if (_api == null) {
      await _append(
        WalletTransaction(
          id: _newId('recharge'),
          type: WalletTransactionType.recharge,
          amountCents: amountCents,
          title: '本地测试充值',
          createdAt: DateTime.now(),
        ),
      );
      return RechargeCreateResult(
        order: RechargeOrder(
          id: _newId('local_order'),
          outTradeNo: _newId('LOCAL'),
          provider: provider,
          tradeType: tradeType,
          amountCents: amountCents,
          status: 'paid',
        ),
        payment: RechargePayment(
          provider: provider,
          tradeType: tradeType,
          paymentReady: false,
          message: '本地测试模式已直接入账',
        ),
        wallet: state,
      );
    }
    final result = await _api.createRecharge(
      amountCents: amountCents,
      provider: provider,
      tradeType: tradeType,
    );
    state = result.wallet;
    await _persist();
    return result;
  }

  Future<RechargeOrder> refreshRechargeStatus({
    String? orderId,
    String? outTradeNo,
  }) async {
    if (_api == null) {
      return RechargeOrder(
        id: orderId ?? '',
        outTradeNo: outTradeNo ?? '',
        provider: '',
        tradeType: '',
        amountCents: 0,
        status: 'paid',
      );
    }
    final order = await _api.fetchRechargeStatus(
      orderId: orderId,
      outTradeNo: outTradeNo,
    );
    await syncFromServer();
    return order;
  }

  Future<RechargeOrder> cancelRecharge({
    String? orderId,
    String? outTradeNo,
  }) async {
    if (_api == null) {
      return RechargeOrder(
        id: orderId ?? '',
        outTradeNo: outTradeNo ?? '',
        provider: '',
        tradeType: '',
        amountCents: 0,
        status: 'closed',
      );
    }
    final order = await _api.cancelRecharge(
      orderId: orderId,
      outTradeNo: outTradeNo,
    );
    await syncFromServer();
    return order;
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
    if (_api == null) {
      throw const ServerWalletException('当前钱包未连接服务端');
    }
    final result = await _api.generateAiReport(
      productId: productId,
      featureKey: featureKey,
      title: title,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: temperature,
      sourceJson: sourceJson,
    );
    state = result.wallet;
    await _persist();
    return result;
  }

  Future<void> replaceFromServer(WalletState wallet) async {
    state = wallet;
    await _persist();
  }

  Future<void> clearLocalSession() async {
    state = const WalletState();
    await _persist();
  }

  Future<WalletChargeResult> charge({
    required int amountCents,
    required String title,
    required String featureKey,
    required String productId,
  }) async {
    if (amountCents <= 0) {
      return const WalletChargeResult(
        success: false,
        message: '当前档位金额无效',
      );
    }
    if (state.balanceCents < amountCents) {
      return WalletChargeResult(
        success: false,
        message:
            '余额不足，还需 ${formatWalletCents(amountCents - state.balanceCents)}',
      );
    }

    final transaction = WalletTransaction(
      id: _newId('charge'),
      type: WalletTransactionType.charge,
      amountCents: -amountCents,
      title: title,
      featureKey: featureKey,
      productId: productId,
      createdAt: DateTime.now(),
    );
    await _append(transaction);
    return WalletChargeResult(
      success: true,
      message: '扣费成功',
      transactionId: transaction.id,
    );
  }

  Future<void> refund({
    required String transactionId,
    required int amountCents,
    required String title,
  }) async {
    if (amountCents <= 0) return;
    await _append(
      WalletTransaction(
        id: _newId('refund'),
        type: WalletTransactionType.refund,
        amountCents: amountCents,
        title: title,
        relatedTransactionId: transactionId,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _append(WalletTransaction transaction) async {
    state = state.copyWith(
      balanceCents: state.balanceCents + transaction.amountCents,
      transactions: [transaction, ...state.transactions],
    );
    await _persist();
  }

  Future<void> _load() async {
    if (_api != null) {
      try {
        state = await _api.fetchWallet();
        await _persist();
        return;
      } catch (_) {
        // Use the last cached snapshot while the user is logged out or the API
        // is still warming up. Mutating operations still require the server.
      }
    }
    try {
      final raw = await readLocalJson(_storageKey);
      if (raw == null || raw.isEmpty) return;
      state = WalletState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt local wallet data should not block app startup.
    }
  }

  Future<void> _persist() async {
    await writeLocalJson(_storageKey, jsonEncode(state.toJson()));
  }

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}

String formatWalletCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  final major = abs ~/ 100;
  final minor = abs % 100;
  if (minor == 0) return '$sign¥$major';
  if (minor % 10 == 0) return '$sign¥$major.${minor ~/ 10}';
  return '$sign¥$major.${minor.toString().padLeft(2, '0')}';
}
