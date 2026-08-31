import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/common/common_result_models.dart';
import '../../domain/history/divination_history.dart';
import '../../features/auth/auth_store.dart';
import '../../features/account/user_data_api.dart';
import '../local_persistence/local_json_store.dart';

/// 历史记录服务。
///
/// Web 本地预览下写入浏览器 localStorage；测试/非 Web 环境使用内存兜底。
class HistoryService extends ChangeNotifier {
  static const _storageKeyPrefix = 'guoxueapp.divination_history.v1';

  final List<DivinationHistory> _records = [];
  final String ownerKey;
  final String _storageKey;
  final String _deletedStorageKey;
  final String? _token;
  final UserDataApi? _cloudApi;
  final Set<String> _pendingDeletedIds = {};
  bool _syncing = false;

  HistoryService({
    String? ownerKey,
    String? token,
    UserDataApi? cloudApi,
  })  : ownerKey = _normalizeOwnerKey(ownerKey),
        _storageKey = '$_storageKeyPrefix.${_normalizeOwnerKey(ownerKey)}',
        _deletedStorageKey =
            '$_storageKeyPrefix.${_normalizeOwnerKey(ownerKey)}.deleted',
        _token = token,
        _cloudApi = cloudApi {
    _load();
  }

  static String ownerKeyFromAuth(AuthState auth) {
    final user = auth.user;
    if (auth.isAuthenticated && user != null) {
      if (user.id.isNotEmpty) return 'user_${user.id}';
      if (user.phone?.isNotEmpty == true) return 'phone_${user.phone}';
    }
    return 'guest';
  }

  static String _normalizeOwnerKey(String? raw) {
    final value = raw == null || raw.trim().isEmpty ? 'guest' : raw.trim();
    return value.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
  }

  void save(DivinationHistory record) {
    final updated = _withUpdatedAt(record, DateTime.now());
    _records.removeWhere((r) => r.id == updated.id);
    _records.insert(0, updated);
    _persist();
    notifyListeners();
    _syncRecords([updated]);
  }

  List<DivinationHistory> getAll() => List.unmodifiable(_records);

  List<DivinationHistory> getRecent(int limit) => _records.take(limit).toList();

  DivinationHistory? getById(String id) {
    try {
      return _records.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  void delete(String id) {
    _records.removeWhere((r) => r.id == id);
    _persist();
    notifyListeners();
    _syncDeleted([id]);
  }

  DivinationHistory saveResultSnapshot(CommonDivinationResult result) {
    final idx = _records.indexWhere((record) => _matchesResult(record, result));
    final old = idx >= 0 ? _records[idx] : null;
    final oldSnapshot =
        old == null ? const <String, dynamic>{} : old.resultSnapshot;
    final updatedSnapshot = Map<String, dynamic>.from(oldSnapshot)
      ..addAll(result.toJson());
    final record = DivinationHistory(
      id: old?.id ??
          '${result.featureId}_${DateTime.now().millisecondsSinceEpoch}',
      featureId: result.featureId,
      featureName: result.featureName,
      question: result.userQuestion,
      createdAt: result.createdAt,
      updatedAt: DateTime.now(),
      summary: result.summary,
      resultJson: const JsonEncoder().convert(updatedSnapshot),
      tags: result.tags ?? old?.tags ?? const [],
      isFavorite: old?.isFavorite ?? false,
    );
    if (idx >= 0) {
      _records[idx] = record;
    } else {
      _records.insert(0, record);
    }
    _persist();
    notifyListeners();
    _syncRecords([record]);
    return record;
  }

  bool attachAiReportToResult(
    CommonDivinationResult result,
    AiReportSnapshot report,
  ) {
    final idx = _records.indexWhere((record) => _matchesResult(record, result));
    if (idx < 0) return false;

    final raw = Map<String, dynamic>.from(_records[idx].resultSnapshot);
    final restored = CommonDivinationResult.fromJson(raw);
    final updatedResult = restored.copyWithAiReport(report);
    saveResultSnapshot(updatedResult);
    return true;
  }

  void toggleFavorite(String id) {
    final idx = _records.indexWhere((r) => r.id == id);
    if (idx < 0) return;
    final old = _records[idx];
    _records[idx] = DivinationHistory(
      id: old.id,
      featureId: old.featureId,
      featureName: old.featureName,
      question: old.question,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
      summary: old.summary,
      resultJson: old.resultJson,
      tags: old.tags,
      isFavorite: !old.isFavorite,
    );
    _persist();
    notifyListeners();
    _syncRecords([_records[idx]]);
  }

  List<DivinationHistory> search(String keyword) {
    if (keyword.isEmpty) return getAll();
    final kw = keyword.toLowerCase();
    return _records.where((r) {
      if (r.question?.toLowerCase().contains(kw) == true) return true;
      if (r.featureName.toLowerCase().contains(kw)) return true;
      if (r.summary.toLowerCase().contains(kw)) return true;
      try {
        final snap = r.resultSnapshot;
        for (final key in ['primaryHexagram', 'changedHexagram', 'movingYao']) {
          final obj = snap[key];
          if (obj is Map) {
            final name =
                (obj['name'] ?? obj['lineName'])?.toString().toLowerCase();
            if (name != null && name.contains(kw)) return true;
          }
        }
        final dc = snap['derivedCast'];
        if (dc is Map) {
          for (final key in ['primaryHexagram', 'changedHexagram']) {
            final obj = dc[key];
            if (obj is Map &&
                obj['name']?.toString().toLowerCase().contains(kw) == true) {
              return true;
            }
          }
          final my = dc['movingYao'];
          if (my is Map &&
              my['lineName']?.toString().toLowerCase().contains(kw) == true) {
            return true;
          }
        }
        final fr = snap['finalResult'];
        if (fr is Map) {
          if (fr['finalVerdict']?.toString().toLowerCase().contains(kw) ==
              true) {
            return true;
          }
          if (fr['vernacular']?.toString().toLowerCase().contains(kw) == true) {
            return true;
          }
        }
      } catch (_) {}
      return false;
    }).toList();
  }

  List<DivinationHistory> filterByFeature(String featureId) {
    if (featureId == 'all') return getAll();
    if (featureId == 'favorite') {
      return _records.where((r) => r.isFavorite).toList();
    }
    return _records.where((r) => r.featureId == featureId).toList();
  }

  List<DivinationHistory> searchAndFilter({
    String keyword = '',
    String featureId = 'all',
  }) {
    if (keyword.isEmpty) return filterByFeature(featureId);
    return search(keyword).where((r) {
      if (featureId == 'all') return true;
      if (featureId == 'favorite') return r.isFavorite;
      return r.featureId == featureId;
    }).toList();
  }

  int get count => _records.length;

  int get weeklyCount {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _records.where((r) => r.createdAt.isAfter(weekAgo)).length;
  }

  int get favoriteCount => _records.where((r) => r.isFavorite).length;

  Future<void> clearLocalData() async {
    _records.clear();
    _pendingDeletedIds.clear();
    await _persist();
    await _persistPendingDeletes();
    notifyListeners();
  }

  /// 删除当前用户的历史记录，并同步删除云端副本。
  ///
  /// 钱包、充值订单、AI 报告和命盘档案不属于历史记录，因此不会受影响。
  /// 云端暂时不可用时，待删除编号会留在本机，下一次同步时继续删除。
  Future<bool> clearAllHistory() async {
    final ids = _records.map((record) => record.id).toList();
    _records.clear();
    _pendingDeletedIds.addAll(ids);
    await _persist();
    await _persistPendingDeletes();
    notifyListeners();

    final token = _token;
    final api = _cloudApi;
    if (ids.isEmpty || token == null || token.isEmpty || api == null) {
      return true;
    }

    try {
      await api.sync(token, deletedHistoryIds: ids);
      _pendingDeletedIds.removeAll(ids);
      await _persistPendingDeletes();
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _matchesResult(
    DivinationHistory record,
    CommonDivinationResult result,
  ) {
    if (record.featureId != result.featureId) return false;
    try {
      final snapshot = record.resultSnapshot;
      if (snapshot['createdAt'] == result.createdAt.toIso8601String()) {
        return true;
      }
      return (snapshot['summary'] as String? ?? record.summary) ==
              result.summary &&
          (snapshot['userQuestion'] as String? ?? record.question) ==
              result.userQuestion;
    } catch (_) {
      return record.summary == result.summary &&
          record.question == result.userQuestion;
    }
  }

  Future<void> _load() async {
    try {
      await _loadPendingDeletes();
      final raw = await readLocalJson(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _records
          ..clear()
          ..addAll(
            decoded.map(
              (item) => DivinationHistory.fromJson(
                item as Map<String, dynamic>,
              ),
            ),
          );
        notifyListeners();
      }
      await _initialCloudSync();
    } catch (_) {
      // 本地缓存损坏时不阻塞页面；下一次保存会重写快照。
      await _initialCloudSync();
    }
  }

  Future<void> _initialCloudSync() async {
    final token = _token;
    final api = _cloudApi;
    if (token == null || token.isEmpty || api == null || _syncing) return;
    _syncing = true;
    try {
      if (_pendingDeletedIds.isNotEmpty) {
        await api.sync(
          token,
          deletedHistoryIds: _pendingDeletedIds.toList(),
        );
        _pendingDeletedIds.clear();
        await _persistPendingDeletes();
      }
      final snapshots = _records.map((item) => item.toJson()).toList();
      var cloud = await api.fetch(token);
      for (var offset = 0; offset < snapshots.length; offset += 25) {
        final end =
            offset + 25 < snapshots.length ? offset + 25 : snapshots.length;
        cloud = await api.sync(
          token,
          histories: snapshots.sublist(offset, end),
        );
      }
      final merged = <String, DivinationHistory>{
        for (final item in _records) item.id: item,
      };
      for (final raw in cloud.histories) {
        final remote = DivinationHistory.fromJson(raw);
        if (_pendingDeletedIds.contains(remote.id)) continue;
        final local = merged[remote.id];
        if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
          merged[remote.id] = remote;
        }
      }
      _records
        ..clear()
        ..addAll(merged.values);
      _records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _persist();
      notifyListeners();
    } catch (_) {
      // 云端不可用时继续使用本地记录，下次登录或修改时会再次同步。
    } finally {
      _syncing = false;
    }
  }

  void _syncRecords(List<DivinationHistory> records) {
    final token = _token;
    final api = _cloudApi;
    if (token == null || token.isEmpty || api == null) return;
    unawaited(api
        .sync(
          token,
          histories: records.map((item) => item.toJson()).toList(),
        )
        .then<void>((_) {}, onError: (_) {}));
  }

  void _syncDeleted(List<String> ids) {
    _pendingDeletedIds.addAll(ids);
    unawaited(_persistPendingDeletes());
    final token = _token;
    final api = _cloudApi;
    if (token == null || token.isEmpty || api == null) return;
    unawaited(api.sync(token, deletedHistoryIds: ids).then<void>((_) {
      _pendingDeletedIds.removeAll(ids);
      return _persistPendingDeletes();
    }, onError: (_) {}));
  }

  Future<void> _loadPendingDeletes() async {
    try {
      final raw = await readLocalJson(_deletedStorageKey);
      if (raw == null || raw.isEmpty) return;
      _pendingDeletedIds.addAll((jsonDecode(raw) as List).cast<String>());
    } catch (_) {
      _pendingDeletedIds.clear();
    }
  }

  Future<void> _persistPendingDeletes() {
    return writeLocalJson(
      _deletedStorageKey,
      jsonEncode(_pendingDeletedIds.toList()),
    );
  }

  DivinationHistory _withUpdatedAt(
    DivinationHistory record,
    DateTime updatedAt,
  ) {
    return DivinationHistory(
      id: record.id,
      featureId: record.featureId,
      featureName: record.featureName,
      question: record.question,
      createdAt: record.createdAt,
      updatedAt: updatedAt,
      summary: record.summary,
      resultJson: record.resultJson,
      tags: record.tags,
      isFavorite: record.isFavorite,
    );
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(_records.map((item) => item.toJson()).toList());
    await writeLocalJson(_storageKey, encoded);
  }
}

final historyServiceProvider = ChangeNotifierProvider<HistoryService>((ref) {
  final auth = ref.watch(authStoreProvider);
  return HistoryService(
    ownerKey: HistoryService.ownerKeyFromAuth(auth),
    token: auth.token,
    cloudApi: auth.isAuthenticated ? UserDataApi() : null,
  );
});
