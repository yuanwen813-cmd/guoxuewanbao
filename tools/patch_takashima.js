const fs = require('fs');
const f = 'lib/features/divination/takashima/takashima_page.dart';
let c = fs.readFileSync(f, 'utf8');

// Find and replace: the build method that returns GuoxueResultPage
const marker = 'GuoxueResultPage(result:_result!';
const i = c.indexOf(marker);
if (i < 0) { console.log('marker not found'); process.exit(1); }

// Find the entire line
const lineStart = c.lastIndexOf('\n', i) + 1;
let lineEnd = c.indexOf('\n', i);
if (lineEnd < 0) lineEnd = c.length;
const oldLine = c.substring(lineStart, lineEnd);
console.log('Old line length:', oldLine.length);

// The replacement section to insert BEFORE the build method
const insertBefore = `
  CommonDivinationResult _toCommonResult() {
    final cr = _castResult!;
    final p = cr.primaryHexagram; final c = cr.changedHexagram; final my = cr.movingYao;
    final fq = _isFinancialQuestion(cr.question);
    final summary = '本卦'+p.name+' '+p.symbol+'  动爻'+my.lineName+'  之卦'+c.name+' '+c.symbol;
    return CommonDivinationResult(
      featureId: 'takashima', featureName: '高岛易断', categoryId: 'divination',
      userQuestion: cr.question.isNotEmpty ? cr.question : null,
      createdAt: DateTime.now(), summary: summary, type: DivinationType.hexagram,
      primaryHexagram: HexagramCard(index: p.index, name: p.name, symbol: p.symbol, upperTrigram: p.upper.name, lowerTrigram: p.lower.name, judgment: p.judgment, image: p.image),
      movingYao: MovingYaoCard(line: my.position, lineName: my.lineName, text: my.text, meaning: my.meaning),
      changedHexagram: HexagramCard(index: c.index, name: c.name, symbol: c.symbol, judgment: c.judgment, image: c.image),
      xiangDuan: _finalResult?['xiangDuan'] as String?,
      movingYaoAnalysis: _finalResult?['movingYaoAnalysis'] as String?,
      primaryHexagramAnalysis: _finalResult?['primaryHexagramAnalysis'] as String?,
      changedHexagramAnalysis: _finalResult?['changedHexagramAnalysis'] as String?,
      classical: _finalResult?['classical'] as String?,
      vernacular: _finalResult?['vernacular'] as String?,
      timing: _finalResult?['timing'] as String?,
      advice: _finalResult?['advice'] as String?,
      riskNote: _finalResult?['riskNote'] as String?,
      finalVerdict: _finalResult?['finalVerdict'] as String?,
      tags: (_finalResult?['tags'] as List?)?.cast<String>(),
      isFinancial: fq, isMedical: false, isLegal: false,
      rawSnapshot: {'castResult': cr.toJson(), 'finalResult': _finalResult, 'debugJson': _buildDebugJson()},
    );
  }

  void _saveToHistory() {
    final cr = _toCommonResult();
    final record = DivinationHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      featureId: cr.featureId, featureName: cr.featureName,
      question: cr.userQuestion, createdAt: cr.createdAt,
      summary: cr.summary, resultJson: const JsonEncoder().convert(cr.toJson()),
      tags: cr.tags ?? [],
    );
    ref.read(historyServiceProvider).save(record);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存到历史记录')));
  }

  void _shareResult() {
    final text = CommonDivinationResultPage.buildShareText(_toCommonResult());
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('分享结果'),
      content: SizedBox(width: double.maxFinite, height: 400, child: SingleChildScrollView(child: SelectableText(text, style: const TextStyle(fontSize: 13)))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))],
    ));
  }

`;

// New build line
const newLine = '    if(_result!=null)return CommonDivinationResultPage(result:_toCommonResult(),onAIInterpret:_interpreting?null:_aiInterpret,onSave:_saveToHistory,onShare:_shareResult,onRetry:_reset,onDebugExport:_exportDebug,showDebugButton:true);';

// Replace
c = c.substring(0, lineStart) + insertBefore + newLine + c.substring(lineEnd);
fs.writeFileSync(f, c);
console.log('Patched OK');
