import 'dart:html' as html;

Future<bool> openApkDownload(String url) async {
  final anchor = html.AnchorElement(href: url)
    ..download = 'guoxuewanbao.apk'
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return true;
}
