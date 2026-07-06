import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/common/common_result_models.dart';
import '../../domain/history/divination_history.dart';
import '../local_persistence/local_json_store.dart';

/// 历史记录服务。
///
/// Web 本地预览下写入浏览器 localStorage；测试/非 Web 环境使用内存兜底。
class HistoryService extends ChangeNotifier {
  static const _storageKey = 'guoxueapp.divination_history.v1';

  final List<DivinationHistory> _records = [];

  HistoryService() {
    _load();
  }

  void save(DivinationHistory record) {
    _records.removeWhere((r) => r.id == record.id);
    _records.insert(0, record);
    _persist();
    notifyListeners();
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
  }

  bool attachAiReportToResult(
    CommonDivinationResult result,
    AiReportSnapshot report,
  ) {
    final idx = _records.indexWhere((record) => _matchesResult(record, result));
    if (idx < 0) return false;

    final old = _records[idx];
    final raw = Map<String, dynamic>.from(old.resultSnapshot);
    final restored = CommonDivinationResult.fromJson(raw);
    final updatedResult = restored.copyWithAiReport(report);
    final updatedSnapshot = Map<String, dynamic>.from(raw)
      ..addAll(updatedResult.toJson());

    _records[idx] = DivinationHistory(
      id: old.id,
      featureId: old.featureId,
      featureName: old.featureName,
      question: old.question,
      createdAt: old.createdAt,
      summary: old.summary,
      resultJson: const JsonEncoder().convert(updatedSnapshot),
      tags: old.tags,
      isFavorite: old.isFavorite,
    );
    _persist();
    notifyListeners();
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
      summary: old.summary,
      resultJson: old.resultJson,
      tags: old.tags,
      isFavorite: !old.isFavorite,
    );
    _persist();
    notifyListeners();
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
      final raw = await readLocalJson(_storageKey);
      if (raw == null || raw.isEmpty) return;
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
    } catch (_) {
      // 本地缓存损坏时不阻塞页面；下一次保存会重写快照。
    }
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(_records.map((item) => item.toJson()).toList());
    await writeLocalJson(_storageKey, encoded);
  }
}

final historyServiceProvider =
    ChangeNotifierProvider<HistoryService>((ref) => HistoryService());
