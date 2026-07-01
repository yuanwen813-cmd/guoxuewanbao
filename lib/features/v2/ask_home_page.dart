import 'package:flutter/material.dart';

import 'feature_catalog_v2.dart';
import 'v2_page_scaffold.dart';

class AskHomePage extends StatelessWidget {
  const AskHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return V2PageScaffold(
      title: '问事',
      subtitle: '有件事拿不准？用金钱卦、小六壬、梅花易数、高岛易断帮你理清当前局势。',
      icon: Icons.question_answer_outlined,
      children: [
        const V2SectionTitle(title: '常用问事'),
        const V2FeatureList(entries: FeatureCatalogV2.askFeatures),
      ],
    );
  }
}
