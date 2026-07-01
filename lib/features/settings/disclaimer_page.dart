import 'package:flutter/material.dart';

/// 免责声明页面
class DisclaimerPage extends StatelessWidget {
  const DisclaimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('免责声明')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('免责声明', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('1. 文化娱乐性质'),
            Text('本应用（国学万宝匣）提供的所有术数测算结果和 AI 解读内容，均基于传统民俗文化模型与人工智能文本生成技术，仅供传统文化研究、民俗学习和娱乐参考之用。'),
            SizedBox(height: 12),
            Text('2. 非专业建议'),
            Text('本应用不提供以下专业建议：'),
            Text('  - 医疗诊断或治疗建议'),
            Text('  - 法律意见或诉讼建议'),
            Text('  - 投资理财决策建议'),
            Text('  - 婚姻家庭决策建议'),
            Text('  - 任何涉及人身安全或重大财产的决策'),
            SizedBox(height: 12),
            Text('3. 结果可靠性'),
            Text('  - 本地术数引擎基于传统算法，但结果可能因历法差异、流派差异产生偏差。'),
            Text('  - AI 解读由大语言模型生成，可能存在不准确、不完整或不恰当的内容。'),
            Text('  - 本应用不对测算结果的准确性、完整性或适用性做任何保证。'),
            SizedBox(height: 12),
            Text('4. 用户责任'),
            Text('  - 用户应理性看待测算结果，不应将其作为重要决策的唯一依据。'),
            Text('  - 涉及健康、法律、投资等重大事项，请咨询相关专业机构。'),
            Text('  - 使用本应用即表示你已理解并同意本免责声明。'),
          ],
        ),
      ),
    );
  }
}
