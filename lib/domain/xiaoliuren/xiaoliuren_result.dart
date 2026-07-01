import '../wuxing/wuxing.dart';

/// 小六壬六掌位置
enum PalmPosition {
  daAn(0, '大安', '吉', WuXing.wood, '身不动时，五行属木，颜色青色，方位东方。临青龙，谋事主一、五、七。'),
  liuLian(1, '留连', '凶', WuXing.water, '人未归时，五行属水，颜色黑色，方位北方。临玄武，凡谋事主二、八、十。'),
  suXi(2, '速喜', '吉', WuXing.fire, '人便至时，五行属火，颜色红色，方位南方。临朱雀，谋事主三、六、九。'),
  chiKou(3, '赤口', '凶', WuXing.metal, '官事凶时，五行属金，颜色白色，方位西方。临白虎，谋事主四、七、十。'),
  xiaoJi(4, '小吉', '吉', WuXing.water, '人来喜时，五行属水，临六合，谋事主一、五、七。'),
  kongWang(5, '空亡', '大凶', WuXing.earth, '音信稀时，五行属土，颜色黄色，方位中央。临勾陈，谋事主三、六、九。');

  final int order;
  final String name;
  final String auspiciousness;
  final WuXing wuxing;
  final String description;

  const PalmPosition(
    this.order,
    this.name,
    this.auspiciousness,
    this.wuxing,
    this.description,
  );

  bool get isAuspicious => auspiciousness == '吉';
}

/// 小六壬计算结果
class XiaoLiuRenResult {
  final PalmPosition position;
  final int month;
  final int day;
  final String hourBranchName;
  final Map<String, dynamic> toJsonCache;

  const XiaoLiuRenResult({
    required this.position,
    required this.month,
    required this.day,
    required this.hourBranchName,
    this.toJsonCache = const {},
  });

  Map<String, dynamic> toJson() => {
    'method': 'xiaoliuren',
    'position': position.name,
    'positionName': position.name,
    'auspiciousness': position.auspiciousness,
    'wuxing': position.wuxing.chinese,
    'description': position.description,
    'month': month,
    'day': day,
    'hourBranch': hourBranchName,
  };

  @override
  String toString() =>
    '小六壬结果：$month月$day日 ${hourBranchName}时 → ${position.name}(${position.auspiciousness})';
}
