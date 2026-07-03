import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/almanac/almanac_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/bazi/bazi_page.dart';
import '../../features/category/category_page.dart';
import '../../features/v2/ask_home_page.dart';
import '../../features/v2/classics_home_page.dart';
import '../../features/v2/coming_soon_page.dart';
import '../../features/v2/experimental_notice_page.dart';
import '../../features/v2/home_page_v2.dart';
import '../../features/v2/main_shell.dart';
import '../../features/v2/mine_home_page.dart';
import '../../features/v2/natal_profile_models.dart';
import '../../features/v2/natal_profiles_page.dart';
import '../../features/v2/natal_reading_page.dart';
import '../../features/v2/natal_result_section_page.dart';
import '../../features/v2/natal_result_sections.dart';
import '../../features/v2/natal_result_overview_page.dart';
import '../../features/v2/natal_home_page.dart';
import '../../features/v2/standalone_destiny_page.dart';
import '../../features/wallet/wallet_page.dart';
import '../../features/home/home_page.dart';
import '../../features/history/history_detail_page.dart';
import '../../features/history/history_page.dart';
import '../../features/money_hexagram/money_hexagram_page.dart';
import '../../features/placeholder/placeholder_page.dart';
import '../../features/recommend/recommend_page.dart';
import '../../features/result/result_page.dart';
import '../../features/settings/disclaimer_page.dart';
import '../../features/settings/privacy_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/xiaoliuren/xiaoliuren_page.dart';
import '../../features/daily_hexagram/daily_hexagram_page.dart';
import '../../features/divination/meihua/meihua_page.dart';
import '../../features/divination/coin_hexagram/coin_hexagram_page.dart';
import '../../features/divination/small_liuren/small_liuren_page.dart';
import '../../features/divination/takashima/takashima_page.dart';
import '../../features/lot_drawing/lot_drawing_engine.dart';
import '../../features/lot_drawing/lot_drawing_page.dart';
import '../../features/reference_tools/batch2_engines.dart';
import '../../features/reference_tools/generic_feature_page.dart';
import '../../features/zhouyi/zhouyi_page.dart';
import '../../features/zhouyi/takashima_reference_page.dart';
import '../../domain/unified/unified_models.dart';
import '../registry/feature_registry.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // ====== ShellRoute：底部导航栏 ======
      ShellRoute(
        builder: (context, state, child) => GuoxueMainShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            name: RouteNames.home,
            builder: (context, state) => const HomePageV2(),
          ),
          GoRoute(
            path: '/ask',
            name: RouteNames.askHome,
            builder: (context, state) => const AskHomePage(),
          ),
          GoRoute(
            path: '/natal',
            name: RouteNames.natalHome,
            builder: (context, state) => const NatalHomePage(),
          ),
          GoRoute(
            path: '/mine',
            name: RouteNames.mineHome,
            builder: (context, state) => const MineHomePage(),
          ),
        ],
      ),

      // ====== v0.56 二级入口 ======
      GoRoute(
        path: '/classics',
        name: RouteNames.classics,
        builder: (context, state) => const ClassicsHomePage(),
      ),
      GoRoute(
        path: '/natal/reading',
        name: RouteNames.natalReading,
        builder: (context, state) => const NatalReadingPage(),
      ),
      GoRoute(
        path: '/natal/reading/result',
        name: RouteNames.natalReadingResult,
        builder: (context, state) => NatalResultOverviewPage(
          profile:
              state.extra is BirthProfile ? state.extra! as BirthProfile : null,
        ),
      ),
      GoRoute(
        path: '/natal/reading/result/section/:sectionType',
        name: RouteNames.natalResultSection,
        builder: (context, state) => NatalResultSectionPage(
          sectionType: NatalResultSectionType.fromRouteValue(
            state.pathParameters['sectionType'] ?? '',
          ),
          profile:
              state.extra is BirthProfile ? state.extra! as BirthProfile : null,
        ),
      ),
      GoRoute(
        path: '/natal/profiles',
        name: RouteNames.natalProfiles,
        builder: (context, state) => const NatalProfilesPage(),
      ),
      GoRoute(
        path: '/natal/tieban',
        name: RouteNames.natalTieban,
        builder: (context, state) => const StandaloneDestinyPage(
          type: StandaloneDestinyType.tieban,
        ),
      ),
      GoRoute(
        path: '/natal/ziwei',
        name: RouteNames.natalZiwei,
        builder: (context, state) => const StandaloneDestinyPage(
          type: StandaloneDestinyType.ziwei,
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/wallet',
        name: RouteNames.wallet,
        builder: (context, state) => const WalletPage(),
      ),
      GoRoute(
        path: '/coming-soon/:featureId',
        name: RouteNames.comingSoon,
        builder: (context, state) => ComingSoonPage(
          featureId: state.pathParameters['featureId']!,
        ),
      ),
      GoRoute(
        path: '/experimental/:featureId',
        name: RouteNames.experimentalNotice,
        builder: (context, state) => ExperimentalNoticePage(
          featureId: state.pathParameters['featureId']!,
        ),
      ),

      // ====== 保留旧稳定链路 ======
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: '/legacy-home',
            name: 'legacy_home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/history',
            name: RouteNames.history,
            builder: (context, state) => const HistoryPage(),
          ),
          GoRoute(
            path: '/history/detail/:id',
            name: 'history_detail',
            builder: (context, state) => HistoryDetailPage(
              recordId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/reference',
            name: RouteNames.reference,
            builder: (context, state) => const AlmanacPage(),
          ),
        ],
      ),

      // ====== 8 大分类浏览页 ======
      for (final catId in _allCategoryIds)
        GoRoute(
          path: '/category/$catId',
          name: 'category_$catId',
          builder: (context, state) => CategoryPage(categoryId: catId),
        ),

      // ====== 占卜类 (Divination) ======
      GoRoute(
        path: '/recommend',
        name: RouteNames.recommend,
        builder: (context, state) => const RecommendPage(),
      ),
      GoRoute(
        path: '/divination/xiaoliuren',
        name: RouteNames.xiaoliuren,
        builder: (context, state) => const XiaoLiuRenPage(),
      ),
      GoRoute(
        path: '/divination/money',
        name: RouteNames.moneyHexagram,
        builder: (context, state) => const MoneyHexagramPage(),
      ),
      // 灵签类（观音/吕祖/关帝/诸葛神算 — 统一 LotDrawingPage）
      GoRoute(
        path: '/divination/zhuge',
        name: RouteNames.zhuge,
        builder: (context, state) =>
            const _LotPage(lotFile: 'zhuge_384.json', featureId: 'zhuge'),
      ),
      GoRoute(
        path: '/divination/guanyin',
        name: RouteNames.guanyin,
        builder: (context, state) =>
            const _LotPage(lotFile: 'guanyin_100.json', featureId: 'guanyin'),
      ),
      GoRoute(
        path: '/divination/lvzu',
        name: RouteNames.lvzu,
        builder: (context, state) =>
            const _LotPage(lotFile: 'lvzu_100.json', featureId: 'lvzu'),
      ),
      GoRoute(
        path: '/divination/guandi',
        name: RouteNames.guandi,
        builder: (context, state) =>
            const _LotPage(lotFile: 'guandi_100.json', featureId: 'guandi'),
      ),
      // 高岛易断 (beta)
      GoRoute(
        path: '/divination/takashima',
        name: RouteNames.takashima,
        builder: (context, state) => const TakashimaPage(),
      ),
      // 金钱卦 (beta)
      GoRoute(
        path: '/divination/coin_hexagram',
        name: RouteNames.coinHexagram,
        builder: (context, state) => const CoinHexagramPage(),
      ),
      // 小六壬 (beta)
      GoRoute(
        path: '/divination/small_liuren',
        name: RouteNames.smallLiuren,
        builder: (context, state) => const SmallLiurenPage(),
      ),
      // 梅花易数 (beta)
      GoRoute(
        path: '/divination/meihua',
        name: RouteNames.meihua,
        builder: (context, state) => const MeihuaYiPage(),
      ),
      // 蓍草/梅花高级/太乙 (planned)
      GoRoute(
        path: '/divination/yarrow',
        name: RouteNames.yarrow,
        builder: (context, state) => _placeholder(context, 'yarrow'),
      ),
      GoRoute(
        path: '/divination/plum_blossom',
        name: RouteNames.plumBlossom,
        builder: (context, state) => _placeholder(context, 'plum_blossom'),
      ),
      GoRoute(
        path: '/divination/taiyi',
        name: RouteNames.taiyi,
        builder: (context, state) => _placeholder(context, 'taiyi'),
      ),

      // ====== 命理类 (Destiny) ======
      GoRoute(
        path: '/destiny/bazi',
        name: RouteNames.bazi,
        builder: (context, state) => const BaziPage(),
      ),
      GoRoute(
        path: '/destiny/chenggu',
        name: RouteNames.chenggu,
        builder: (context, state) => _ChengGuPage(),
      ),
      GoRoute(
        path: '/destiny/shengxiao',
        name: RouteNames.shengxiao,
        builder: (context, state) => _ShengXiaoPage(),
      ),
      GoRoute(
        path: '/destiny/ziwei',
        name: RouteNames.ziwei,
        builder: (context, state) => _placeholder(context, 'ziwei'),
      ),
      GoRoute(
        path: '/destiny/qimen',
        name: RouteNames.qimen,
        builder: (context, state) => _placeholder(context, 'qimen'),
      ),
      GoRoute(
        path: '/destiny/daliuren',
        name: RouteNames.daliuren,
        builder: (context, state) => _placeholder(context, 'daliuren'),
      ),
      GoRoute(
        path: '/destiny/tieban',
        name: RouteNames.tieban,
        builder: (context, state) => _placeholder(context, 'tieban'),
      ),

      // ====== 相术类 (Physiognomy) ======
      GoRoute(
        path: '/physiognomy/mianxiang',
        name: RouteNames.mianxiang,
        builder: (context, state) => _placeholder(context, 'mianxiang'),
      ),
      GoRoute(
        path: '/physiognomy/shouxiang',
        name: RouteNames.shouxiang,
        builder: (context, state) => _placeholder(context, 'shouxiang'),
      ),
      GoRoute(
        path: '/physiognomy/guxiang',
        name: RouteNames.guxiang,
        builder: (context, state) => _placeholder(context, 'guxiang'),
      ),
      GoRoute(
        path: '/physiognomy/shengyin',
        name: RouteNames.shengyin,
        builder: (context, state) => _placeholder(context, 'shengyin'),
      ),

      // ====== 风水类 (Feng Shui) ======
      GoRoute(
        path: '/fengshui/luopan',
        name: RouteNames.luopan,
        builder: (context, state) => _placeholder(context, 'luopan'),
      ),
      GoRoute(
        path: '/fengshui/jiaju',
        name: RouteNames.jiaju,
        builder: (context, state) => _placeholder(context, 'jiaju'),
      ),
      GoRoute(
        path: '/fengshui/bangong',
        name: RouteNames.bangong,
        builder: (context, state) => _placeholder(context, 'bangong'),
      ),
      GoRoute(
        path: '/fengshui/yangzhai',
        name: RouteNames.yangzhai,
        builder: (context, state) => _placeholder(context, 'yangzhai'),
      ),
      GoRoute(
        path: '/fengshui/yinzhai',
        name: RouteNames.yinzhai,
        builder: (context, state) => _placeholder(context, 'yinzhai'),
      ),

      // ====== 择吉类 (Date Selection) ======
      GoRoute(
        path: '/date_selection/zeri',
        name: RouteNames.zeri,
        builder: (context, state) => _placeholder(context, 'zeri'),
      ),
      GoRoute(
        path: '/date_selection/jishi',
        name: RouteNames.jishi,
        builder: (context, state) => _placeholder(context, 'jishi'),
      ),
      GoRoute(
        path: '/date_selection/dongtu',
        name: RouteNames.dongtu,
        builder: (context, state) => _placeholder(context, 'dongtu'),
      ),
      GoRoute(
        path: '/date_selection/jiaqu',
        name: RouteNames.jiaqu,
        builder: (context, state) => _placeholder(context, 'jiaqu'),
      ),

      // ====== 姓名类 (Naming) ======
      GoRoute(
        path: '/naming/xingming',
        name: RouteNames.xingming,
        builder: (context, state) => _placeholder(context, 'xingming'),
      ),
      GoRoute(
        path: '/naming/gongsi',
        name: RouteNames.gongsi,
        builder: (context, state) => _placeholder(context, 'gongsi'),
      ),
      GoRoute(
        path: '/naming/baobao',
        name: RouteNames.baobao,
        builder: (context, state) => _placeholder(context, 'baobao'),
      ),
      GoRoute(
        path: '/naming/biming',
        name: RouteNames.biming,
        builder: (context, state) => _placeholder(context, 'biming'),
      ),

      // ====== 杂占类 (Misc Divination) ======
      GoRoute(
        path: '/misc/zhougong',
        name: RouteNames.zhougong,
        builder: (context, state) => _ZhouGongPage(),
      ),
      GoRoute(
        path: '/misc/niaozhan',
        name: RouteNames.niaozhan,
        builder: (context, state) => _placeholder(context, 'niaozhan'),
      ),
      GoRoute(
        path: '/misc/zizhan',
        name: RouteNames.zizhan,
        builder: (context, state) => _placeholder(context, 'zizhan'),
      ),
      GoRoute(
        path: '/misc/shicao',
        name: RouteNames.shicao,
        builder: (context, state) => _placeholder(context, 'shicao'),
      ),

      // ====== 通书工具类 (Almanac Tools) ======
      GoRoute(
        path: '/tools/almanac',
        name: RouteNames.almanac,
        builder: (context, state) => const AlmanacPage(),
      ),
      GoRoute(
        path: '/reference/jieqi',
        name: RouteNames.jieqi,
        builder: (context, state) => _JieQiPage(),
      ),
      GoRoute(
        path: '/reference/er_shiba_xiu',
        name: RouteNames.erShiBaXiu,
        builder: (context, state) => _ErShiBaXiuPage(),
      ),
      GoRoute(
        path: '/reference/ganzhi',
        name: RouteNames.ganzhiCalendar,
        builder: (context, state) => _GanZhiPage(),
      ),
      GoRoute(
        path: '/reference/wuxing',
        name: RouteNames.wuxingCalc,
        builder: (context, state) => _WuXingPage(),
      ),
      // 周易本经
      GoRoute(
        path: '/reference/zhouyi',
        name: RouteNames.zhouyiBenjing,
        builder: (context, state) => const ZhouyiPage(),
      ),
      GoRoute(
        path: '/reference/takashima',
        name: 'takashima_reference',
        builder: (context, state) => const TakashimaReferencePage(),
      ),

      // ====== 结果详情 ======
      GoRoute(
        path: '/result/:id',
        name: RouteNames.result,
        builder: (context, state) => ResultPage(
          recordId: state.pathParameters['id']!,
        ),
      ),

      // ====== 每日一卦 ======
      GoRoute(
        path: '/daily_hexagram',
        name: RouteNames.dailyHexagram,
        builder: (context, state) => const DailyHexagramPage(),
      ),

      // ====== 通用占位页（动态路由） ======
      GoRoute(
        path: '/placeholder/:featureId',
        name: 'placeholder',
        builder: (context, state) {
          final id = state.pathParameters['featureId']!;
          final registry = ref.read(featureRegistryProvider).valueOrNull;
          final feature = registry?.byId(id);
          if (feature != null) {
            return PlaceholderPage(feature: feature);
          }
          return PlaceholderPage(
            feature: FeatureConfig(
              id: id,
              title: '未知功能',
              subtitle: '',
              categoryId: '',
              route: '',
              icon: 'auto_awesome',
              status: 'planned',
              complexity: 'simple',
              ritualType: 'none',
              engineType: 'placeholder',
              requiresBirthInfo: false,
              requiresQuestion: false,
              supportsHistory: false,
              supportsShare: false,
            ),
          );
        },
      ),

      // ====== 设置 ======
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/settings/privacy',
        name: RouteNames.privacy,
        builder: (context, state) => const PrivacyPage(),
      ),
      GoRoute(
        path: '/settings/disclaimer',
        name: RouteNames.disclaimer,
        builder: (context, state) => const DisclaimerPage(),
      ),
    ],
  );
});

// ===== Batch-2 页面工厂 =====

class _LotPage extends ConsumerStatefulWidget {
  final String lotFile;
  final String featureId;
  const _LotPage({required this.lotFile, required this.featureId});
  @override
  ConsumerState<_LotPage> createState() => _LotPageState();
}

class _LotPageState extends ConsumerState<_LotPage> {
  LotConfig? _config;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await LotConfig.load(widget.lotFile);
    if (mounted) setState(() => _config = c);
  }

  @override
  Widget build(BuildContext context) {
    if (_config == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return LotDrawingPage(lotConfig: _config!, featureId: widget.featureId);
  }
}

Widget _ChengGuPage() => GenericFeaturePage(
      featureId: 'chenggu',
      title: '称骨算命',
      iconName: 'balance',
      promptTemplateId: 'chenggu_interpret',
      inputFields: const [
        InputFieldConfig(
            key: 'year',
            label: '出生年份',
            type: InputFieldType.number,
            required: true,
            defaultValue: 1990,
            min: 1924,
            max: 2030),
        InputFieldConfig(
            key: 'month',
            label: '出生月份',
            type: InputFieldType.number,
            required: true,
            defaultValue: 1,
            min: 1,
            max: 12),
        InputFieldConfig(
            key: 'day',
            label: '出生日',
            type: InputFieldType.number,
            required: true,
            defaultValue: 1,
            min: 1,
            max: 31),
        InputFieldConfig(
            key: 'hour',
            label: '出生时辰',
            type: InputFieldType.number,
            required: true,
            defaultValue: 0,
            min: 0,
            max: 23),
        InputFieldConfig(
            key: 'question',
            label: '所想之事',
            type: InputFieldType.multiline,
            hint: '选填...',
            maxLength: 200,
            maxLines: 2),
      ],
      calculator: (inputs) => ChengGuEngine().calculate(
        inputs['year'] as int,
        inputs['month'] as int,
        inputs['day'] as int,
        inputs['hour'] as int,
      ),
    );

Widget _ShengXiaoPage() => GenericFeaturePage(
      featureId: 'shengxiao',
      title: '生肖运势',
      iconName: 'cruelty_free',
      promptTemplateId: 'shengxiao_interpret',
      inputFields: const [
        InputFieldConfig(
            key: 'shengxiao',
            label: '选择生肖',
            type: InputFieldType.dropdown,
            required: true,
            defaultValue: 1,
            options: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]),
        InputFieldConfig(
            key: 'question',
            label: '所想之事',
            type: InputFieldType.multiline,
            hint: '选填...',
            maxLength: 200,
            maxLines: 2),
      ],
      calculator: (inputs) =>
          ShengXiaoEngine().calculate(inputs['shengxiao'] as int),
    );

Widget _ZhouGongPage() => GenericFeaturePage(
      featureId: 'zhougong',
      title: '周公解梦',
      iconName: 'bedtime',
      promptTemplateId: 'jiemeng_interpret',
      ritualText: '输入你的梦境内容，AI会结合传统周公解梦为你解读。\n尽量描述清楚梦中的关键元素（人、物、场景）。',
      inputFields: const [
        InputFieldConfig(
            key: 'dream',
            label: '梦境描述',
            type: InputFieldType.multiline,
            required: true,
            hint: '例如：梦见自己在天上飞，突然掉进水里...',
            maxLength: 500,
            maxLines: 5),
        InputFieldConfig(
            key: 'question',
            label: '额外想问的',
            type: InputFieldType.multiline,
            hint: '选填...',
            maxLength: 200,
            maxLines: 2),
      ],
      calculator: (inputs) =>
          ZhouGongDreamEngine().calculate(inputs['dream'] as String),
    );

Widget _JieQiPage() => GenericFeaturePage(
      featureId: 'jieqi',
      title: '节气查询',
      iconName: 'ac_unit',
      inputFields: const [
        InputFieldConfig(
            key: 'year',
            label: '年份',
            type: InputFieldType.number,
            required: true,
            defaultValue: 2026,
            min: 1900,
            max: 2100),
      ],
      calculator: (inputs) => JieQiEngine().calculate(inputs['year'] as int),
    );

Widget _ErShiBaXiuPage() => GenericFeaturePage(
      featureId: 'er_shiba_xiu',
      title: '二十八宿',
      iconName: 'nightlight_round',
      inputFields: const [],
      calculator: (_) => ErShiBaXiuEngine().calculate(),
    );

Widget _GanZhiPage() => GenericFeaturePage(
      featureId: 'ganzhi_calendar',
      title: '干支日历',
      iconName: 'view_column',
      inputFields: const [
        InputFieldConfig(
            key: 'date',
            label: '选择日期',
            type: InputFieldType.date,
            required: true),
      ],
      calculator: (inputs) {
        final ds = inputs['date'] as String? ?? '';
        final parts = ds.split('-');
        final d = parts.length == 3
            ? DateTime(
                int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))
            : DateTime.now();
        return GanZhiCalendarEngine().calculate(d);
      },
    );

Widget _WuXingPage() => GenericFeaturePage(
      featureId: 'wuxing_calc',
      title: '五行计算器',
      iconName: 'blur_on',
      inputFields: const [
        InputFieldConfig(
            key: 'element',
            label: '选择五行',
            type: InputFieldType.dropdown,
            defaultValue: '木',
            options: ['木', '火', '土', '金', '水']),
      ],
      calculator: (inputs) =>
          WuXingCalculatorEngine().calculate(inputs['element'] as String?),
    );

// ===== 路由占位页 =====

/// 所有 8 个分类 ID
const _allCategoryIds = [
  'daily_tools',
  'iching_divination',
  'quick_divination',
  'destiny_chart',
  'lot_drawing',
  'fengshui_compass',
  'date_selection',
  'entertainment',
];

/// 路由占位页（通过 featureId 从 registry 动态加载配置）
class _RoutePlaceholder extends ConsumerWidget {
  final String featureId;
  const _RoutePlaceholder(this.featureId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(featureRegistryProvider).valueOrNull;
    final feature = registry?.byId(featureId);
    if (feature != null) {
      return PlaceholderPage(feature: feature);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('敬请期待')),
      body: const Center(child: Text('功能规划中')),
    );
  }
}

Widget _placeholder(BuildContext context, String featureId) {
  return _RoutePlaceholder(featureId);
}
