import 'package:uuid/uuid.dart';

import '../dto/divination_record.dart';
import '../dto/interpretation.dart';
import '../ports/history_repository.dart';

/// 保存历史记录用例
class SaveHistoryUseCase {
  final HistoryRepository _repository;
  final Uuid _uuid;

  const SaveHistoryUseCase(this._repository, [Uuid? uuid])
      : _uuid = uuid ?? const Uuid();

  Future<DivinationRecord> execute({
    required String methodId,
    required String methodName,
    required String question,
    required Map<String, dynamic> inputJson,
    required Map<String, dynamic> resultJson,
    Interpretation? interpretation,
  }) async {
    final record = DivinationRecord(
      id: _uuid.v4(),
      methodId: methodId,
      methodName: methodName,
      question: question,
      inputJson: inputJson,
      resultJson: resultJson,
      interpretationJson: interpretation?.toJson(),
      createdAt: DateTime.now(),
    );

    await _repository.save(record);
    return record;
  }
}
