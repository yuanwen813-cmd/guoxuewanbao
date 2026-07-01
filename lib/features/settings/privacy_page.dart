import 'package:flutter/material.dart';

/// 隐私政策页面
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私政策')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('隐私政策', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('最后更新日期：2024年1月'),
            SizedBox(height: 16),
            Text('1. 数据收集'),
            Text('本应用仅在用户主动输入时收集以下信息：'),
            Text('  - 出生日期（用于八字排盘）'),
            Text('  - 性别信息（用于命理分析）'),
            Text('  - 用户提出的问题文本'),
            Text('  - 用户配置的 API Key'),
            SizedBox(height: 12),
            Text('2. 数据存储'),
            Text('  - 所有计算结果和历史记录默认存储在本地设备。'),
            Text('  - API Key 使用系统级加密存储。'),
            Text('  - 不会自动上传任何数据到第三方服务器。'),
            SizedBox(height: 12),
            Text('3. AI 调用'),
            Text('  - 当使用 AI 解读功能时，你的问题和本地计算结果会发送到 DeepSeek API。'),
            Text('  - 建议配置自定义 API Key 以保护隐私。'),
            SizedBox(height: 12),
            Text('4. 用户权利'),
            Text('  - 你可以在设置中随时清除所有本地数据。'),
            Text('  - 你可以随时删除 API Key 配置。'),
          ],
        ),
      ),
    );
  }
}
