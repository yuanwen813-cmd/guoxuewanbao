import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/history/divination_history.dart';
import 'package:guoxueapp/features/account/user_data_api.dart';
import 'package:guoxueapp/infrastructure/history_service/history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('signed-in history restores from cloud without dropping local records',
      () async {
    final local = _record('local_record', DateTime(2026, 8, 27, 10));
    final remote = _record('remote_record', DateTime(2026, 8, 27, 11));
    final api = _FakeUserDataApi(histories: [remote.toJson()]);
    final owner = 'sync_merge_${DateTime.now().microsecondsSinceEpoch}';
    final service = HistoryService(
      ownerKey: owner,
      token: 'token',
      cloudApi: api,
    );
    service.save(local);

    await _waitFor(() => service.count == 2);

    expect(service.getById(local.id), isNotNull);
    expect(service.getById(remote.id), isNotNull);
    expect(api.histories.map((item) => item['id']), contains(local.id));
    service.dispose();
  });

  test('offline deletion tombstone prevents a cloud record from returning',
      () async {
    final record = _record('delete_record', DateTime(2026, 8, 27, 12));
    final cloud = [record.toJson()];
    final owner = 'sync_delete_${DateTime.now().microsecondsSinceEpoch}';
    final offlineApi = _FakeUserDataApi(
      histories: cloud,
      failDeletes: true,
    );
    final first = HistoryService(
      ownerKey: owner,
      token: 'token',
      cloudApi: offlineApi,
    );
    await _waitFor(() => first.getById(record.id) != null);
    first.delete(record.id);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(first.getById(record.id), isNull);
    expect(offlineApi.histories, isNotEmpty);
    first.dispose();

    final onlineApi = _FakeUserDataApi(histories: offlineApi.histories);
    final second = HistoryService(
      ownerKey: owner,
      token: 'token',
      cloudApi: onlineApi,
    );
    await _waitFor(() => onlineApi.deletedHistoryIds.contains(record.id));

    expect(second.getById(record.id), isNull);
    expect(onlineApi.histories, isEmpty);
    second.dispose();
  });
}

DivinationHistory _record(String id, DateTime time) {
  return DivinationHistory(
    id: id,
    featureId: 'coin_hexagram',
    featureName: '金钱卦',
    question: '测试问题',
    createdAt: time,
    updatedAt: time,
    summary: '测试结果',
    resultJson: '{}',
  );
}

Future<void> _waitFor(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for async sync');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _FakeUserDataApi extends UserDataApi {
  _FakeUserDataApi({
    List<Map<String, dynamic>> histories = const [],
    this.failDeletes = false,
  })  : histories = histories.map(Map<String, dynamic>.from).toList(),
        super(baseUrl: 'http://127.0.0.1');

  final List<Map<String, dynamic>> histories;
  final bool failDeletes;
  final List<String> deletedHistoryIds = [];

  @override
  Future<UserCloudData> fetch(String token) async {
    return UserCloudData(histories: _snapshot());
  }

  @override
  Future<UserCloudData> sync(
    String token, {
    List<Map<String, dynamic>> histories = const [],
    List<Map<String, dynamic>> profiles = const [],
    List<String> deletedHistoryIds = const [],
    List<String> deletedProfileIds = const [],
  }) async {
    if (failDeletes && deletedHistoryIds.isNotEmpty) {
      throw StateError('offline');
    }
    this.deletedHistoryIds.addAll(deletedHistoryIds);
    this.histories.removeWhere(
          (item) => deletedHistoryIds.contains(item['id']),
        );
    for (final record in histories) {
      this.histories.removeWhere((item) => item['id'] == record['id']);
      this.histories.add(Map<String, dynamic>.from(record));
    }
    return UserCloudData(histories: _snapshot());
  }

  List<Map<String, dynamic>> _snapshot() {
    return histories.map(Map<String, dynamic>.from).toList();
  }
}
