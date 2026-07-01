import 'package:flutter/material.dart';

import 'feature_catalog_v2.dart';
import 'v2_page_scaffold.dart';

class MineHomePage extends StatelessWidget {
  const MineHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const V2PageScaffold(
      title: '我的',
      subtitle: '管理你的问事记录、命盘档案、报告和钱包。',
      icon: Icons.person_outline,
      children: [
        V2SectionTitle(title: '我的资产'),
        V2FeatureList(entries: FeatureCatalogV2.mineFeatures),
      ],
    );
  }
}
