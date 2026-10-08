import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AiReportContent extends StatelessWidget {
  final String text;

  const AiReportContent({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownBody(
      data: text,
      selectable: true,
      softLineBreak: true,
      imageBuilder: (uri, title, alt) => Text(alt ?? '图片'),
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
        h1: theme.textTheme.titleLarge?.copyWith(fontSize: 20, height: 1.4),
        h2: theme.textTheme.titleMedium?.copyWith(fontSize: 18, height: 1.4),
        h3: theme.textTheme.titleSmall?.copyWith(fontSize: 16, height: 1.4),
        blockSpacing: 16,
        listIndent: 20,
        tableColumnWidth: const FlexColumnWidth(),
        tableCellsPadding: const EdgeInsets.all(6),
      ),
    );
  }
}
