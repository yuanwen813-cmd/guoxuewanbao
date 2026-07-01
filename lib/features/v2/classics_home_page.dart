import 'package:flutter/material.dart';

import 'feature_catalog_v2.dart';
import 'v2_page_scaffold.dart';

class ClassicsHomePage extends StatelessWidget {
  const ClassicsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const V2PageScaffold(
      title: '资料入口',
      subtitle: '查阅周易本经、高岛易断等经典资料。',
      icon: Icons.library_books_outlined,
      showAppBar: true,
      children: [
        V2SectionTitle(title: '经典资料'),
        V2FeatureList(entries: FeatureCatalogV2.classicsFeatures),
      ],
    );
  }
}
