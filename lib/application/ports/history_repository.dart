import '../dto/divination_record.dart';

/// 历史记录仓储抽象接口
abstract class HistoryRepository {
  Future<void> save(DivinationRecord record);
  Future<List<DivinationRecord>> getAll({int? limit, int? offset});
  Future<DivinationRecord?> getById(String id);
  Future<void> delete(String id);
  Future<void> toggleFavorite(String id);
  Future<void> clearAll();
}
