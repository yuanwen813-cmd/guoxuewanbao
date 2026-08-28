import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadHtmlFile({
  required String filename,
  required String html,
  required String subject,
}) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  await file.writeAsString(html, flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/html')],
    subject: subject,
    text: '国学万宝匣个人数据导出文件',
  );
}
