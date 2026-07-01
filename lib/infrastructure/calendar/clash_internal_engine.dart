/// 冲煞开发内测引擎 v0.50
/// 基于日支计算冲生肖和煞方位。日支unavailable→冲煞unavailable。

class ClashInternalResult {
  final String? clashZodiac; final String? shaDirection;
  final String? dayBranch; final String source; final String status; final String? unavailableReason;

  const ClashInternalResult({
    this.clashZodiac, this.shaDirection, this.dayBranch,
    this.source = 'clash_internal_v0_50', this.status = 'internal', this.unavailableReason,
  });

  static const unavailable = ClashInternalResult(status: 'unavailable', unavailableReason: 'day branch unavailable → clash unavailable');

  Map<String, dynamic> toJson() => {
    if (clashZodiac != null) 'clashZodiac': clashZodiac,
    if (shaDirection != null) 'shaDirection': shaDirection,
    if (dayBranch != null) 'dayBranch': dayBranch,
    'source': source, 'status': status,
    if (unavailableReason != null) 'unavailableReason': unavailableReason,
  };
}

class ClashInternalEngine {
  const ClashInternalEngine();

  /// 十二地支六冲关系
  static const _clashMap = {
    '子': '午', '丑': '未', '寅': '申', '卯': '酉',
    '辰': '戌', '巳': '亥', '午': '子', '未': '丑',
    '申': '寅', '酉': '卯', '戌': '辰', '亥': '巳',
  };

  /// 地支→生肖
  static const _branchToZodiac = {
    '子': '鼠', '丑': '牛', '寅': '虎', '卯': '兔',
    '辰': '龙', '巳': '蛇', '午': '马', '未': '羊',
    '申': '猴', '酉': '鸡', '戌': '狗', '亥': '猪',
  };

  /// 地支→煞方位
  static const _shaDirection = {
    '子': '南', '丑': '东', '寅': '北', '卯': '西',
    '辰': '南', '巳': '东', '午': '北', '未': '西',
    '申': '南', '酉': '东', '戌': '北', '亥': '西',
  };

  /// 计算冲煞候选
  ClashInternalResult compute(String? dayBranch) {
    if (dayBranch == null || dayBranch.isEmpty) return ClashInternalResult.unavailable;
    final clashBranch = _clashMap[dayBranch];
    if (clashBranch == null) return ClashInternalResult.unavailable;
    final clashZodiac = _branchToZodiac[clashBranch] ?? '';
    final shaDir = _shaDirection[dayBranch] ?? '';
    return ClashInternalResult(clashZodiac: clashZodiac, shaDirection: shaDir, dayBranch: dayBranch);
  }

  Map<String, dynamic> buildDebugJson() => {
    'schemaVersion': 'clash-internal-engine-v0_50',
    'method': '日支六冲+煞方位', 'source': 'clash_internal_v0_50',
    'sixClashPairs': const ['子午', '丑未', '寅申', '卯酉', '辰戌', '巳亥'],
  };
}
