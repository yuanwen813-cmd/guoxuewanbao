import 'dart:html' as html;

Future<String?> readLocalJsonImpl(String key) async {
  return html.window.localStorage[key];
}

Future<void> writeLocalJsonImpl(String key, String value) async {
  html.window.localStorage[key] = value;
}

Future<void> deleteLocalJsonImpl(String key) async {
  html.window.localStorage.remove(key);
}
