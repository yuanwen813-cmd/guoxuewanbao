import 'package:flutter/material.dart';

import 'feature_catalog_v2.dart';
import 'v2_page_scaffold.dart';

class CalendarHomePage extends StatelessWidget {
  const CalendarHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const V2PageScaffold(
      title: '日历',
      subtitle: '查看今日宜忌，选择更合适的行动时机。',
      icon: Icons.today_outlined,
      children: [
        V2SectionTitle(title: '日历工具'),
        V2FeatureList(entries: FeatureCatalogV2.calendarFeatures),
      ],
    );
  }
}
