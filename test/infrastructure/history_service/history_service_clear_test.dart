import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/history/divination_history.dart';
import 'package:guoxueapp/infrastructure/history_service/history_service.dart';

void main() {
  test('clearing history removes persisted records for the current owner',
      () async {
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final ownerKey = 'history_clear_$suffix';
    final recordId = 'history_clear_record_$suffix';
    final service = HistoryService(ownerKey: ownerKey);
    await Future<void>.delayed(const Duration(milliseconds: 1));

    service.save(
      DivinationHistory(
        id: recordId,
        featureId: 'coin_hexagram',
        featureName: '金钱卦',
        createdAt: DateTime.now(),
        summary: '待清除的历史记录',
        resultJson: '{}',
      ),
    );

    expect(service.getById(recordId), isNotNull);
    expect(await service.clearAllHistory(), isTrue);
    expect(service.getById(recordId), isNull);

    final reloaded = HistoryService(ownerKey: ownerKey);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(reloaded.getById(recordId), isNull);
  });
}
