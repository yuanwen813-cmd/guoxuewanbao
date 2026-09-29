import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/local_persistence/local_json_store.dart';
import '../auth/auth_store.dart';
import 'server_wallet_api.dart';

final walletStoreProvider = StateNotifierProvider<WalletStore, WalletState>(
  (ref) {
    final userId = ref.watch(authStoreProvider.select((auth) => auth.user?.id));
    return WalletStore(
      api: ServerWalletApi(
        tokenProvider: () async {
          final auth = ref.read(authStoreProvider);
          return auth.user?.id == userId ? auth.token : null;
        },
      ),
    );
  },
);

class WalletState {
  final int balanceCents;
  final String currency;
  final String? updatedAt;
  final List<WalletTransaction> transactions;
  final bool hasTransactions;

  const WalletState({
    this.balanceCents = 0,
    this.currency = 'CNY',
    this.updatedAt,
    List<WalletTransaction>? transactions,
  })  : transactions = transactions ?? const [],
        hasTransactions = transactions != null;

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
          : null,
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
      WalletTransactionType.recharge => '积分充值',
      WalletTransactionType.aiDebit => 'AI 解析扣积分',
      WalletTransactionType.aiRefund => 'AI 失败退积分',
      WalletTransactionType.manualAdjust => '积分调整',
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
  int _session = 0;
  int _revision = 0;

  bool _isCurrent(int session) => mounted && session == _session;

  void _mergeWallet(WalletState wallet) {
    _revision++;
    state = wallet.hasTransactions
        ? wallet
        : wallet.copyWith(transactions: state.transactions);
  }

  Future<void> _refreshQuietly() async {
    try {
      await syncFromServer();
    } catch (_) {
      // A refresh failure must not turn a settled report into a failed one.
    }
  }

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
      await createRecharge(
        amountCents: yuan * 100,
        provider: 'wechat',
        tradeType: 'web_native',
      );
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
    if (_api == null || !mounted) return;
    final session = _session;
    final revision = ++_revision;
    final wallet = await _api.fetchWallet();
    if (!_isCurrent(session) || revision != _revision) return;
    _mergeWallet(wallet);
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
    final session = _session;
    final result = await _api.createRecharge(
      amountCents: amountCents,
      provider: provider,
      tradeType: tradeType,
    );
    if (!_isCurrent(session)) return result;
    _mergeWallet(result.wallet);
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
    final session = _session;
    final order = await _api.fetchRechargeStatus(
      orderId: orderId,
      outTradeNo: outTradeNo,
    );
    if (_isCurrent(session)) await syncFromServer();
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
    final session = _session;
    final order = await _api.cancelRecharge(
      orderId: orderId,
      outTradeNo: outTradeNo,
    );
    if (_isCurrent(session)) await syncFromServer();
    return order;
  }

  Future<ServerAiReportResult> generateAiReport({
    required String productId,
    required String featureKey,
    required String title,
    required String systemPrompt,
    required String userPrompt,
    required double temperature,
    required int expectedPointsCenti,
    required String requestId,
    String? sourceJson,
  }) async {
    if (_api == null) {
      throw const ServerWalletException('当前钱包未连接服务端');
    }
    final session = _session;
    final result = await _api.generateAiReport(
      productId: productId,
      featureKey: featureKey,
      title: title,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: temperature,
      expectedPointsCenti: expectedPointsCenti,
      requestId: requestId,
      sourceJson: sourceJson,
    );
    if (!_isCurrent(session)) return result;
    _mergeWallet(result.wallet);
    await _persist();
    if (_isCurrent(session)) unawaited(_refreshQuietly());
    return result;
  }

  Future<void> replaceFromServer(WalletState wallet) async {
    if (!mounted) return;
    _mergeWallet(wallet);
    await _persist();
    if (mounted) unawaited(_refreshQuietly());
  }

  Future<void> clearLocalSession() async {
    if (!mounted) return;
    _session++;
    _revision++;
    state = const WalletState();
    await _persist();
  }

  Future<WalletChargeResult> charge({
    required int amountCents,
    required String title,
    required String featureKey,
    required String productId,
  }) async {
    if (_api != null) {
      return const WalletChargeResult(success: false, message: '积分只能由服务端扣减');
    }
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
            '积分不足，还需 ${formatPointsCenti(amountCents - state.balanceCents)}',
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
      message: '积分扣除成功',
      transactionId: transaction.id,
    );
  }

  Future<void> refund({
    required String transactionId,
    required int amountCents,
    required String title,
  }) async {
    if (_api != null) throw StateError('积分只能由服务端退回');
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
      // Remove the pre-isolation cache; server state is always account-owned.
      unawaited(deleteLocalJson(_storageKey).catchError((_) {}));
      await _refreshQuietly();
      return;
    }
    final session = _session;
    final revision = _revision;
    try {
      final raw = await readLocalJson(_storageKey);
      if (!_isCurrent(session) || revision != _revision) return;
      if (raw == null || raw.isEmpty) return;
      state = WalletState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt local wallet data should not block app startup.
    }
  }

  Future<void> _persist() async {
    // Server wallets are not restored from a device-wide, cross-account cache.
    if (_api != null) return;
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

String formatPointsCenti(int centiPoints) {
  final sign = centiPoints < 0 ? '-' : '';
  final abs = centiPoints.abs();
  final major = abs ~/ 100;
  final minor = abs % 100;
  if (minor == 0) return '$sign$major 积分';
  if (minor % 10 == 0) return '$sign$major.${minor ~/ 10} 积分';
  return '$sign$major.${minor.toString().padLeft(2, '0')} 积分';
}
