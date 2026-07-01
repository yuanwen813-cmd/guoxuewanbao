import '../../domain/calendar/ganzhi.dart';
import '../../domain/calendar/solar_term.dart';
import '../../domain/unified/unified_models.dart';
import '../../domain/wuxing/wuxing.dart';
import '../../domain/wuxing/shengke.dart';

// ====================================================================
// 1. 称骨算命引擎
// ====================================================================

/// 年月日时骨重表（袁天罡称骨歌）
class ChengGuEngine {
  static const _yearWeights = {
    1924:0.8,1925:0.9,1926:0.6,1927:0.8,1928:0.8,1929:0.7,1930:0.6,1931:0.8,1932:0.7,1933:0.8,
    1934:1.5,1935:0.9,1936:1.6,1937:0.8,1938:0.8,1939:1.9,1940:1.2,1941:0.6,1942:0.8,1943:0.7,
    1944:0.5,1945:1.5,1946:0.6,1947:1.6,1948:1.5,1949:0.7,1950:0.9,1951:1.2,1952:1.0,1953:0.7,
    1954:1.5,1955:0.6,1956:0.5,1957:1.4,1958:1.4,1959:0.9,1960:0.7,1961:0.7,1962:0.9,1963:1.2,
    1964:0.8,1965:0.7,1966:1.3,1967:0.5,1968:1.4,1969:0.5,1970:0.9,1971:1.7,1972:0.5,1973:0.7,
    1974:1.2,1975:0.8,1976:0.8,1977:0.6,1978:1.9,1979:0.6,1980:0.8,1981:1.6,1982:1.0,1983:0.7,
    1984:1.2,1985:0.9,1986:0.6,1987:0.7,1988:1.2,1989:0.5,1990:0.9,1991:0.8,1992:0.7,1993:0.8,
    1994:1.5,1995:0.9,1996:1.6,1997:0.8,1998:0.8,1999:1.9,2000:1.2,2001:0.6,2002:0.8,2003:0.7,
    2004:0.5,2005:1.5,2006:0.6,2007:1.6,2008:1.5,2009:0.7,2010:0.9,2011:1.2,2012:1.0,2013:0.7,
    2014:1.5,2015:0.6,2016:0.8,2017:1.4,2018:1.4,2019:0.9,2020:0.7,2021:0.7,2022:0.9,2023:1.2,
    2024:0.8,2025:0.7,2026:1.3,2027:0.5,2028:1.4,2029:0.5,2030:0.9,
  };

  static const _monthWeights = {
    1:0.6,2:0.7,3:1.8,4:0.9,5:0.5,6:1.6,7:0.9,8:1.5,9:1.8,10:0.8,11:0.9,12:0.5,
  };

  static const _dayWeights = {
    1:0.5,2:1.0,3:0.8,4:1.5,5:1.6,6:1.5,7:0.8,8:1.6,9:0.8,10:1.6,
    11:0.9,12:1.7,13:0.8,14:1.7,15:1.0,16:0.8,17:0.9,18:1.8,19:0.5,20:1.5,
    21:1.0,22:0.9,23:0.8,24:0.9,25:1.5,26:1.8,27:0.7,28:0.8,29:1.6,30:0.6,
  };

  static const _hourWeights = {
    0:1.6,1:0.6,2:0.7,3:1.0,4:0.9,5:1.6,6:1.0,7:0.8,8:0.8,9:0.9,10:0.6,11:0.5,
    12:1.6,13:0.6,14:0.7,15:1.0,16:0.9,17:1.6,18:1.0,19:0.8,20:0.8,21:0.9,22:0.6,23:0.5,
  };

  /// 称骨歌诀（按总重量）
  static final _songJue = {
    2.1: '短命非业谓大凶，平生灾难事重重。凶祸频临陷逆境，终世困苦事不成。',
    2.2: '身寒骨冷苦伶仃，此命推来行乞人。劳劳碌碌无度日，终年打拱过平生。',
    2.3: '此命推来骨格轻，求谋作事事难成。妻儿兄弟应难许，别处他乡作散人。',
    2.4: '此命推来福禄无，门庭困苦总难荣。六亲骨肉皆无靠，流浪他乡作老翁。',
    2.5: '此命推来祖业微，门庭营度似稀奇。六亲骨肉如冰炭，一世勤劳自把持。',
    2.6: '平生衣禄苦中求，独自营谋事不休。离祖出门宜早计，晚来衣禄自无休。',
    2.7: '一生作事少商量，难靠祖宗作主张。独马单枪空做去，早年晚岁总无长。',
    2.8: '一生行事似飘蓬，祖宗产业在梦中。若不过房改名姓，也当移徒二三通。',
    2.9: '初年运限未曾亨，纵有功名在后成。须过四旬才可立，移居改姓始为良。',
    3.0: '劳劳碌碌苦中求，东奔西走何日休。若使终身勤与俭，老来稍可免忧愁。',
    3.1: '忙忙碌碌苦中求，何日云开见日头。难得祖基家可立，中年衣食渐无忧。',
    3.2: '初年运蹇事难谋，渐有财源如水流。到得中年衣食旺，那时名利一齐收。',
    3.3: '早年做事事难成，百年勤劳枉费心。半世自如流水去，后来运到始得金。',
    3.4: '此命福气果如何，僧道门中衣禄多。离祖出家方为妙，朝晚拜佛念弥陀。',
    3.5: '生平福量不周全，祖业根基觉少传。营事生涯宜守旧，时来衣食胜从前。',
    3.6: '不须劳碌过平生，独自成家福不轻。早有福星常照命，任君行去百般成。',
    3.7: '此命般般事不成，弟兄少力自孤行。虽然祖业须微有，来得明时去不明。',
    3.8: '一身骨肉最清高，早入簧门姓氏标。待到年将三十六，蓝衫脱去换红袍。',
    3.9: '此命终身运不通，劳劳作事尽皆空。苦心竭力成家计，到得那时在梦中。',
    4.0: '平生衣禄是绵长，件件心中自主张。前面风霜多受过，后来必定享安康。',
    4.1: '此命推来自不同，为人能干异凡庸。中年还有逍遥福，不比前时运未通。',
    4.2: '得宽怀处且宽怀，何用双眉皱不开。若使中年命运济，那时名利一起来。',
    4.3: '为人心性最聪明，作事轩昂近贵人。衣禄一生天注定，不须劳碌是丰亨。',
    4.4: '万事由天莫苦求，须知福碌赖人修。当年财帛难如意，晚景欣然便不忧。',
    4.5: '名利推求竟若何，前番辛苦后奔波。命中难养男和女，骨肉扶持也不多。',
    4.6: '东西南北尽皆通，出姓移居更觉隆。衣禄无穷无数定，中年晚景一般同。',
    4.7: '此命推求旺末年，妻荣子贵自怡然。平生原有滔滔福，可卜财源若水泉。',
    4.8: '初年运道未曾通，几许蹉跎命亦穷。兄弟六亲无依靠，一生事业晚来隆。',
    4.9: '此命推来福不轻，自成自立显门庭。从来富贵人钦敬，使婢差奴过一生。',
    5.0: '为利为名终日劳，中年福禄也多遭。老来自有财星照，不比前番目下高。',
  };

  GuoxueResult calculate(int year, int month, int day, int hour) {
    final yw = _yearWeights[year] ?? 1.0;
    final mw = _monthWeights[month] ?? 0.9;
    final dw = _dayWeights[day] ?? 1.0;
    final hw = _hourWeights[hour ~/ 2 % 12 * 2] ?? 0.9;
    final total = (yw + mw + dw + hw * 10).round() / 10.0;

    final jue = _songJue[total] ?? '此命骨重${total}两，命理通达，一切顺遂。';

    return GuoxueResult(
      featureId: 'chenggu',
      featureTitle: '称骨算命',
      categoryId: 'destiny',
      createdAt: DateTime.now(),
      sections: [
        ResultSection(title: '骨重明细', type: ResultSectionType.kvTable, kvPairs: [
          MapEntry('年重', '$yw 两'),
          MapEntry('月重', '$mw 两'),
          MapEntry('日重', '$dw 两'),
          MapEntry('时重', '$hw 两'),
        ]),
        ResultSection(title: '总骨重', type: ResultSectionType.text, text: '${total.toStringAsFixed(1)} 两'),
        ResultSection(title: '称骨歌诀', type: ResultSectionType.text, text: jue),
        ResultSection(title: '骨重判断', type: ResultSectionType.tags, tags: [
          if (total < 2.5) '骨重较轻' else if (total < 3.5) '骨重中等' else if (total < 4.5) '骨重较佳' else '骨重厚重',
          '袁天罡称骨法',
        ]),
      ],
      rawData: {'yearWeight': yw, 'monthWeight': mw, 'dayWeight': dw, 'hourWeight': hw, 'total': total, 'songJue': jue},
    );
  }
}

// ====================================================================
// 2. 生肖运势引擎
// ====================================================================

class ShengXiaoEngine {
  static const _animals = ['鼠','牛','虎','兔','龙','蛇','马','羊','猴','鸡','狗','猪'];
  static const _directions = ['北','东北','东北','东','东南','东南','南','西南','西南','西','西北','西北'];
  static const _luckyNumbers = [[2,3],[1,4],[1,3],[3,6],[4,9],[2,8],[2,7],[3,9],[4,8],[5,8],[3,9],[2,6]];
  static const _luckyColors = ['蓝色','黄色','青色','绿色','金色','红色','紫色','棕色','白色','黄色','红色','黑色'];
  static const _overview = [
    '今年运势总体平稳，贵人运强，适合发展事业。注意健康管理，防范小人。',
    '今年是转运之年，机遇与挑战并存。宜稳扎稳打，不宜冒进。人际关系需多加维护。',
    '今年贵人运势强，事业上有突破机会。但需注意口舌是非，低调行事为宜。',
    '今年桃花运旺，感情生活丰富多彩。事业稳定提升，财运有小幅增长。',
    '今年是本命年，运势起伏较大。建议低调行事，可在年初做化解太岁。',
    '今年智慧开启，学业事业皆有进步。但需注意肠胃健康，规律作息。',
    '今年驿马星动，适合出行远游。事业有变动之象，宜主动求变。',
    '今年福星高照，运势稳中有升。家庭和睦，事业平顺，宜守不宜攻。',
    '今年创造力强，适合创业创新。但需注意投资风险，量力而行。',
    '今年人际关系顺畅，贵人相助。事业发展顺利，但需戒骄戒躁。',
    '今年财运亨通，正财偏财皆有收获。但需注意理财规划，不宜铺张浪费。',
    '今年需多注意身体健康，事业有小人作祟。建议保持低调，少说多做。',
  ];

  GuoxueResult calculate(int shengxiaoIndex) {
    final i = (shengxiaoIndex - 1) % 12; // 1=鼠
    final name = _animals[i];
    return GuoxueResult(
      featureId: 'shengxiao',
      featureTitle: '生肖运势',
      categoryId: 'destiny',
      createdAt: DateTime.now(),
      sections: [
        ResultSection(title: '生肖', type: ResultSectionType.text, text: '属$name'),
        ResultSection(title: '年度总运', type: ResultSectionType.text, text: _overview[i]),
        ResultSection(title: '运势信息', type: ResultSectionType.kvTable, kvPairs: [
          MapEntry('吉利方位', _directions[i]),
          MapEntry('幸运数字', _luckyNumbers[i].join('、')),
          MapEntry('幸运颜色', _luckyColors[i]),
        ]),
        ResultSection(title: '提示', type: ResultSectionType.tags, tags: ['生肖运势', '传统文化', '仅供娱乐']),
      ],
      rawData: {'shengxiao': name, 'index': i, 'overview': _overview[i]},
    );
  }
}

// ====================================================================
// 3. 周公解梦引擎
// ====================================================================

class ZhouGongDreamEngine {
  static final _dreamDB = _buildDB();

  static Map<String, String> _buildDB() {
    final db = <String, String>{};
    // 自然类
    db['水']='梦见水主财运将至，大水主发大财，清水主小财。水清则吉，水浊则凶。';
    db['火']='梦见火主有名望，大火主事业兴旺。但火势过大则需防口舌是非。';
    db['山']='梦见山主有靠山，贵人相助。登山主步步高升，下山主运势回落。';
    db['风']='梦见风主有变动，和风主好事将近，狂风主有波折。';
    // 动物类
    db['蛇']='梦见蛇主有喜事，大蛇主大吉。蛇入怀中主得贵子，蛇咬主得财。';
    db['鱼']='梦见鱼主发财，大鱼主大财。鱼跃水面主喜事临门，捕鱼主收获。';
    db['鸟']='梦见飞鸟主喜讯将至，群鸟主贵人齐聚。鸟鸣主好消息。';
    db['狗']='梦见狗主有朋友相助，恶犬主防小人。犬吠主有口舌。';
    db['猫']='梦见猫主有小人作祟，需提防身边之人。';
    db['马']='梦见马主事业奔腾，白马主吉事。骑马主得志。';
    db['龙']='梦见龙主大吉大利，有贵人相助。龙飞主升迁。';
    // 生活类
    db['水灾']='梦见水灾主财运变动，洪水主有大财但也需防破财。';
    db['火灾']='梦见火灾主事业有大变动，或主名声大噪。';
    db['死人']='梦见死人主增寿，为吉兆。梦见自己死主长寿。';
    db['血']='梦见血主财运，出血主破财，见人血主得财。';
    db['棺材']='梦见棺材主升官发财，"见棺发财"为大吉之兆。';
    db['结婚']='梦见结婚主有喜事，也可能主人生新阶段。';
    db['考试']='梦见考试主有压力，也主即将面临考验。';
    // 身体类
    db['牙齿']='梦见掉牙齿主家中有长辈健康需注意，或主破财。';
    db['头发']='梦见掉头发主有烦恼缠身，白发主智慧增长。';
    // 通用
    db['逃跑']='梦见逃跑主有压力，正在逃避现实中的某些问题。';
    db['飞行']='梦见飞行主渴望自由，事业有上升空间。';
    db['坠落']='梦见坠落主事业或生活有失控感，需稳住当前局面。';
    return db;
  }

  List<MapEntry<String, String>> search(String dreamText) {
    final results = <MapEntry<String, String>>[];
    for (final entry in _dreamDB.entries) {
      if (dreamText.contains(entry.key)) {
        results.add(entry);
      }
    }
    // 按关键词长度降序（更精确的匹配排前面）
    results.sort((a, b) => b.key.length.compareTo(a.key.length));
    return results.take(5).toList();
  }

  GuoxueResult calculate(String dreamText) {
    final matches = search(dreamText);
    if (matches.isEmpty) {
      return GuoxueResult(
        featureId: 'zhougong',
        featureTitle: '周公解梦',
        categoryId: 'misc_divination',
        createdAt: DateTime.now(),
        sections: [
          ResultSection(title: '梦境', type: ResultSectionType.text, text: dreamText),
          ResultSection(title: '解梦结果', type: ResultSectionType.text, text: '梦库中暂未找到匹配的梦境解释。\n建议尝试用更简单的关键词描述梦境（如水、火、蛇、鱼等）。\n或使用 AI 智能解梦获取更全面的解读。'),
        ],
        rawData: {'dream': dreamText, 'matches': []},
      );
    }

    return GuoxueResult(
      featureId: 'zhougong',
      featureTitle: '周公解梦',
      categoryId: 'misc_divination',
      createdAt: DateTime.now(),
      sections: [
        ResultSection(title: '梦境', type: ResultSectionType.text, text: dreamText),
        ...matches.map((m) => ResultSection(
          title: '梦见「${m.key}」',
          type: ResultSectionType.text,
          text: m.value,
        )),
        ResultSection(title: '匹配关键词', type: ResultSectionType.tags, tags: matches.map((m) => m.key).toList()),
      ],
      rawData: {'dream': dreamText, 'matches': matches.map((m) => {'keyword': m.key, 'meaning': m.value}).toList()},
    );
  }
}

// ====================================================================
// 4. 五行计算器
// ====================================================================

class WuXingCalculatorEngine {
  GuoxueResult calculate(String? element) {
    final wuxing = WuXing.values;
    final selected = element != null
        ? wuxing.cast<WuXing?>().firstWhere((w) => w?.chinese == element, orElse: () => null)
        : null;

    return GuoxueResult(
      featureId: 'wuxing_calc',
      featureTitle: '五行计算器',
      categoryId: 'almanac',
      createdAt: DateTime.now(),
      sections: [
        ResultSection(title: '五行列表', type: ResultSectionType.table, table: [
          ['五行', '方位', '颜色', '季节', '脏腑', '五味'],
          ['木', '东', '青', '春', '肝', '酸'],
          ['火', '南', '赤', '夏', '心', '苦'],
          ['土', '中', '黄', '长夏', '脾', '甘'],
          ['金', '西', '白', '秋', '肺', '辛'],
          ['水', '北', '黑', '冬', '肾', '咸'],
        ]),
        if (selected != null) ResultSection(title: '选中五行', type: ResultSectionType.text,
          text: '${selected.chinese} — 方位${['东','南','中','西','北'][selected.index % 5]}，'
              '颜色${['青','赤','黄','白','黑'][selected.index % 5]}，'
              '季节${['春','夏','长夏','秋','冬'][selected.index % 5]}'),
        ResultSection(title: '生克关系', type: ResultSectionType.text,
          text: '木生火、火生土、土生金、金生水、水生木\n'
              '木克土、土克水、水克火、火克金、金克木'),
      ],
      rawData: {'selected': selected?.chinese},
    );
  }
}

// ====================================================================
// 5. 节气查询
// ====================================================================

class JieQiEngine {
  static const _jieqi = [
    '小寒','大寒','立春','雨水','惊蛰','春分','清明','谷雨',
    '立夏','小满','芒种','夏至','小暑','大暑','立秋','处暑',
    '白露','秋分','寒露','霜降','立冬','小雪','大雪','冬至',
  ];

  static const _jieqiDesc = [
    '一年中最冷的时候开始','一年中最后一个节气','春季开始，万物复苏','降雨增多，春雨贵如油','春雷始鸣，蛰虫惊醒','昼夜平分，春意正浓','天清地明，适合踏青','雨生百谷，播种希望',
    '夏季开始，万物生长','麦类灌浆，尚未成熟','有芒作物成熟，播种忙','白昼最长，阳极生阴','暑气初来，尚未最热','一年中最热的时候','秋季开始，暑去凉来','暑气终止，秋高气爽',
    '露凝而白，天气转凉','昼夜平分，秋收在即','露水更冷，即将结冰','气肃而凝，露结为霜','冬季开始，万物收藏','开始降雪，但雪量不大','大雪纷飞，天地苍茫','白昼最短，阴极阳生',
  ];

  GuoxueResult calculate(int year) {
    return GuoxueResult(
      featureId: 'jieqi',
      featureTitle: '节气查询',
      categoryId: 'almanac',
      createdAt: DateTime.now(),
      sections: [
        ResultSection(title: '$year 年节气', type: ResultSectionType.kvTable, kvPairs: [
          for (int i = 0; i < 24; i++)
            MapEntry('${i+1}. ${_jieqi[i]}', _jieqiDesc[i]),
        ]),
        ResultSection(title: '节气歌', type: ResultSectionType.text,
          text: '春雨惊春清谷天，夏满芒夏暑相连。\n秋处露秋寒霜降，冬雪雪冬小大寒。'),
        ResultSection(title: '分类', type: ResultSectionType.tags, tags: [
          '二十四节气', '${year}年', '非物质文化遗产',
        ]),
      ],
      rawData: {'year': year, 'jieqi': _jieqi},
    );
  }
}

// ====================================================================
// 6. 二十八宿
// ====================================================================

class ErShiBaXiuEngine {
  static const _xiu = [
    ['角','亢','氐','房','心','尾','箕'],
    ['斗','牛','女','虚','危','室','壁'],
    ['奎','娄','胃','昴','毕','觜','参'],
    ['井','鬼','柳','星','张','翼','轸'],
  ];

  static const _directions = ['东方青龙', '北方玄武', '西方白虎', '南方朱雀'];

  GuoxueResult calculate() {
    final rows = <List<String>>[['方位', '七宿']];
    for (int i = 0; i < 4; i++) {
      rows.add([_directions[i], _xiu[i].join('、')]);
    }

    return GuoxueResult(
      featureId: 'er_shiba_xiu',
      featureTitle: '二十八宿',
      categoryId: 'almanac',
      createdAt: DateTime.now(),
      sections: [
        ResultSection(title: '四象二十八宿', type: ResultSectionType.table, table: rows),
        ResultSection(title: '说明', type: ResultSectionType.text,
          text: '二十八宿是中国古代天文学将黄道附近的星象划分为二十八个星区，'
              '分属四象：东方青龙七宿、北方玄武七宿、西方白虎七宿、南方朱雀七宿。\n\n'
              '每宿对应一天，28天为一周期，用于择日、占卜等。'),
      ],
      rawData: {'xiu': _xiu},
    );
  }
}

// ====================================================================
// 7. 干支日历
// ====================================================================

class GanZhiCalendarEngine {
  GuoxueResult calculate(DateTime date) {
    final days = _daysSince1900(date.year, date.month, date.day);
    final dayGz = GanZhi(TianGan.fromOrder((days + 10) % 10), DiZhi.fromOrder((days + 12) % 12));
    final yearGz = GanZhi(TianGan.fromOrder((date.year - 4) % 10), DiZhi.fromOrder((date.year - 4) % 12));
    final monthGz = _monthGanZhi(date.year, date.month);
    final hourGz = _hourGanZhi(dayGz.tianGan.order, DateTime.now().hour);

    return GuoxueResult(
      featureId: 'ganzhi_calendar',
      featureTitle: '干支日历',
      categoryId: 'almanac',
      createdAt: DateTime.now(),
      sections: [
        ResultSection(title: '${date.year}年${date.month}月${date.day}日', type: ResultSectionType.kvTable, kvPairs: [
          MapEntry('年柱', yearGz.chineseName),
          MapEntry('月柱', monthGz.chineseName),
          MapEntry('日柱', dayGz.chineseName),
          MapEntry('时柱', hourGz.chineseName),
        ]),
        ResultSection(title: '六十甲子序', type: ResultSectionType.text,
          text: '日柱序号：${((dayGz.tianGan.order * 6 - dayGz.diZhi.order * 5) % 60 + 60) % 60 + 1} / 60'),
        ResultSection(title: '纳音五行', type: ResultSectionType.tags, tags: [
          '${yearGz.chineseName}年',
          '${dayGz.tianGan.wuxing}日',
        ]),
      ],
      rawData: {'date': '${date.year}-${date.month}-${date.day}', 'year': yearGz.chineseName, 'month': monthGz.chineseName, 'day': dayGz.chineseName},
    );
  }

  int _daysSince1900(int y, int m, int d) {
    int days = 0;
    for (int i = 1900; i < y; i++) days += (i % 4 == 0 && i % 100 != 0) || i % 400 == 0 ? 366 : 365;
    const md = [0,31,59,90,120,151,181,212,243,273,304,334];
    days += md[m-1] + d - 1;
    if (m > 2 && ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0)) days++;
    return days;
  }

  GanZhi _monthGanZhi(int year, int month) {
    final yg = TianGan.fromOrder((year - 4) % 10);
    const offsets = [2,4,6,8,0,2,4,6,8,0];
    final mg = (offsets[yg.order % 10] + month - 1) % 10;
    final mz = (month + 1) % 12;
    return GanZhi(TianGan.fromOrder(mg), DiZhi.fromOrder(mz));
  }

  GanZhi _hourGanZhi(int dayGanOrder, int hour) {
    const offsets = [0,2,4,6,8,0,2,4,6,8];
    final hz = hour ~/ 2 % 12;
    final hg = (offsets[dayGanOrder % 10] + hz) % 10;
    return GanZhi(TianGan.fromOrder(hg), DiZhi.fromOrder(hz));
  }
}
