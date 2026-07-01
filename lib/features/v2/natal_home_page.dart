import 'package:flutter/material.dart';

import 'feature_catalog_v2.dart';
import 'v2_page_scaffold.dart';

class NatalHomePage extends StatelessWidget {
  const NatalHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const V2PageScaffold(
      title: '命理',
      subtitle: '输入生辰信息，进入八字命理、铁板神数和紫微斗数。',
      icon: Icons.account_circle_outlined,
      children: [
        V2SectionTitle(title: '命理服务'),
        V2FeatureList(entries: FeatureCatalogV2.natalFeatures),
      ],
    );
  }
}
