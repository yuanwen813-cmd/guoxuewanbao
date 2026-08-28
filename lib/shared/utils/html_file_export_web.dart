import 'dart:html' as web;

Future<void> downloadHtmlFile({
  required String filename,
  required String html,
  required String subject,
}) async {
  final blob = web.Blob([html], 'text/html;charset=utf-8');
  final url = web.Url.createObjectUrlFromBlob(blob);
  final anchor = web.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  web.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  web.Url.revokeObjectUrl(url);
}
