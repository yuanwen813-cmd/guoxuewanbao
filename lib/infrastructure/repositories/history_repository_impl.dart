import 'dart:convert';

import '../../application/dto/divination_record.dart';
import '../../application/ports/history_repository.dart';
import '../database/app_database.dart';

/// 历史记录仓储实现
class HistoryRepositoryImpl implements HistoryRepository {
  final AppDatabase _db;

  HistoryRepositoryImpl(this._db);

  @override
  Future<void> save(DivinationRecord record) async {
    await _db.db.insert(
      'history_records',
      {
        'id': record.id,
        'method_id': record.methodId,
        'method_name': record.methodName,
        'question': record.question,
        'input_json': json.encode(record.inputJson),
        'result_json': json.encode(record.resultJson),
        'interpretation_json': record.interpretationJson != null
            ? json.encode(record.interpretationJson)
            : null,
        'created_at': record.createdAt.millisecondsSinceEpoch,
        'favorite': record.favorite ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<DivinationRecord>> getAll({int? limit, int? offset}) async {
    final rows = await _db.db.query(
      'history_records',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<DivinationRecord?> getById(String id) async {
    final rows = await _db.db.query(
      'history_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<void> delete(String id) async {
    await _db.db.delete('history_records', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final record = await getById(id);
    if (record != null) {
      await _db.db.update(
        'history_records',
        {'favorite': record.favorite ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  @override
  Future<void> clearAll() async {
    await _db.db.delete('history_records');
  }

  DivinationRecord _fromRow(Map<String, dynamic> row) {
    return DivinationRecord(
      id: row['id'] as String,
      methodId: row['method_id'] as String,
      methodName: row['method_name'] as String,
      question: (row['question'] as String?) ?? '',
      inputJson: row['input_json'] != null
          ? json.decode(row['input_json'] as String) as Map<String, dynamic>
          : {},
      resultJson: row['result_json'] != null
          ? json.decode(row['result_json'] as String) as Map<String, dynamic>
          : {},
      interpretationJson: row['interpretation_json'] != null
          ? json.decode(row['interpretation_json'] as String)
              as Map<String, dynamic>
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
      ),
      favorite: (row['favorite'] as int) == 1,
    );
  }
}
