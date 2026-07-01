import 'local_json_store_stub.dart'
    if (dart.library.html) 'local_json_store_web.dart';

Future<String?> readLocalJson(String key) => readLocalJsonImpl(key);

Future<void> writeLocalJson(String key, String value) =>
    writeLocalJsonImpl(key, value);

Future<void> deleteLocalJson(String key) => deleteLocalJsonImpl(key);
