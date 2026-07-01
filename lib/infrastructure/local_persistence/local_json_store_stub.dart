final Map<String, String> _memoryStore = {};

Future<String?> readLocalJsonImpl(String key) async => _memoryStore[key];

Future<void> writeLocalJsonImpl(String key, String value) async {
  _memoryStore[key] = value;
}

Future<void> deleteLocalJsonImpl(String key) async {
  _memoryStore.remove(key);
}
