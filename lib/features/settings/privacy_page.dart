import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私声明')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '隐私声明',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('我们只在你主动使用功能时收集必要信息，并尽量减少不必要的数据保存。'),
            SizedBox(height: 16),
            Text('1. 我们可能使用的信息'),
            Text('  - 手机号码：用于登录、识别钱包归属和查询你的报告。'),
            Text('  - 出生资料：用于生成八字命理、铁板神数、紫微斗数等结构化结果。'),
            Text('  - 所问事项：用于问事、起卦和 AI 解析。'),
            Text('  - 充值与消费记录：用于钱包余额、订单查询和退款核对。'),
            SizedBox(height: 12),
            Text('2. 信息如何保存'),
            Text('  - 登录账户、钱包余额、充值订单和 AI 报告记录保存在服务端。'),
            Text('  - 本地历史和缓存只保存在当前设备，除非你主动登录或使用服务端能力。'),
            Text('  - 钱包余额只能由服务端接口修改，前端不能直接修改余额。'),
            SizedBox(height: 12),
            Text('3. AI 解析如何处理'),
            Text('  - 使用 AI 解析时，系统会把你填写的问题和对应的结构化结果发送到服务端。'),
            Text('  - 服务端再调用 AI 模型生成报告，前端不会保存任何 AI 服务密钥。'),
            Text('  - 报告生成失败时，已扣除的金额会按钱包规则退回。'),
            SizedBox(height: 12),
            Text('4. 你可以做什么'),
            Text('  - 你可以在命盘档案中删除已保存的出生资料。'),
            Text('  - 你可以清除本设备上的历史记录和缓存。'),
            Text('  - 你可以在钱包页面查看余额、充值记录、消费记录和退款记录。'),
            SizedBox(height: 12),
            Text('5. 我们不会做什么'),
            Text('  - 不会在前端暴露服务端密钥、支付私钥或 AI 服务密钥。'),
            Text('  - 不会把你的钱包余额交给前端自行修改。'),
            Text('  - 不会把传统文化参考内容包装成医疗、法律、投资或婚姻等专业建议。'),
          ],
        ),
      ),
    );
  }
}
