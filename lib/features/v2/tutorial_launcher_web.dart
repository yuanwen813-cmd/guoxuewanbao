import 'dart:html' as html;

Future<bool> openTutorial(String url) async {
  html.window.location.assign(url);
  return true;
}
