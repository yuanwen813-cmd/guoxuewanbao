enum BirthRelationship {
  self,
  family,
  friend,
  client,
  other,
}

extension BirthRelationshipLabel on BirthRelationship {
  String get label => switch (this) {
        BirthRelationship.self => '本人',
        BirthRelationship.family => '家人',
        BirthRelationship.friend => '朋友',
        BirthRelationship.client => '客户',
        BirthRelationship.other => '其他',
      };
}

enum BirthGender {
  male,
  female,
  other,
  undisclosed,
}

extension BirthGenderLabel on BirthGender {
  String get label => switch (this) {
        BirthGender.male => '男',
        BirthGender.female => '女',
        BirthGender.other => '其他',
        BirthGender.undisclosed => '不透露',
      };
}

enum BirthTimeAccuracy {
  accurate,
  approximate,
  unknown,
}

extension BirthTimeAccuracyLabel on BirthTimeAccuracy {
  String get label => switch (this) {
        BirthTimeAccuracy.accurate => '准确',
        BirthTimeAccuracy.approximate => '大致',
        BirthTimeAccuracy.unknown => '不确定',
      };
}

class BirthProfile {
  final String id;
  final String ownerUserId;
  final String displayName;
  final BirthRelationship relationship;
  final BirthGender gender;
  final DateTime gregorianBirthDateTime;
  final BirthTimeAccuracy birthTimeAccuracy;
  final String? birthPlaceName;
  final String? lunarBirthDateText;
  final String? notes;
  final bool isSelfProfile;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BirthProfile({
    required this.id,
    required this.ownerUserId,
    required this.displayName,
    required this.relationship,
    required this.gender,
    required this.gregorianBirthDateTime,
    required this.birthTimeAccuracy,
    this.birthPlaceName,
    this.lunarBirthDateText,
    this.notes,
    required this.isSelfProfile,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BirthProfile.create({
    required String displayName,
    required BirthRelationship relationship,
    required BirthGender gender,
    required DateTime gregorianBirthDateTime,
    required BirthTimeAccuracy birthTimeAccuracy,
    String? birthPlaceName,
    String? lunarBirthDateText,
    String? notes,
  }) {
    final now = DateTime.now();
    final safeName = displayName.trim().isEmpty ? '未命名档案' : displayName.trim();
    return BirthProfile(
      id: 'birth_${now.microsecondsSinceEpoch}',
      ownerUserId: 'local_user',
      displayName: safeName,
      relationship: relationship,
      gender: gender,
      gregorianBirthDateTime: gregorianBirthDateTime,
      birthTimeAccuracy: birthTimeAccuracy,
      birthPlaceName: _blankToNull(birthPlaceName),
      lunarBirthDateText: _blankToNull(lunarBirthDateText),
      notes: _blankToNull(notes),
      isSelfProfile: relationship == BirthRelationship.self,
      createdAt: now,
      updatedAt: now,
    );
  }

  BirthProfile copyWith({
    String? id,
    String? ownerUserId,
    String? displayName,
    BirthRelationship? relationship,
    BirthGender? gender,
    DateTime? gregorianBirthDateTime,
    BirthTimeAccuracy? birthTimeAccuracy,
    String? birthPlaceName,
    String? lunarBirthDateText,
    String? notes,
    bool? isSelfProfile,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BirthProfile(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      displayName: displayName ?? this.displayName,
      relationship: relationship ?? this.relationship,
      gender: gender ?? this.gender,
      gregorianBirthDateTime:
          gregorianBirthDateTime ?? this.gregorianBirthDateTime,
      birthTimeAccuracy: birthTimeAccuracy ?? this.birthTimeAccuracy,
      birthPlaceName: birthPlaceName ?? this.birthPlaceName,
      lunarBirthDateText: lunarBirthDateText ?? this.lunarBirthDateText,
      notes: notes ?? this.notes,
      isSelfProfile: isSelfProfile ?? this.isSelfProfile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerUserId': ownerUserId,
      'displayName': displayName,
      'relationship': relationship.name,
      'gender': gender.name,
      'gregorianBirthDateTime': gregorianBirthDateTime.toIso8601String(),
      'birthTimeAccuracy': birthTimeAccuracy.name,
      'birthPlaceName': birthPlaceName,
      'lunarBirthDateText': lunarBirthDateText,
      'notes': notes,
      'isSelfProfile': isSelfProfile,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BirthProfile.fromJson(Map<String, dynamic> json) {
    return BirthProfile(
      id: json['id'] as String,
      ownerUserId: json['ownerUserId'] as String? ?? 'local_user',
      displayName: json['displayName'] as String? ?? '未命名档案',
      relationship: _enumByName(
        BirthRelationship.values,
        json['relationship'] as String?,
        BirthRelationship.other,
      ),
      gender: _enumByName(
        BirthGender.values,
        json['gender'] as String?,
        BirthGender.undisclosed,
      ),
      gregorianBirthDateTime: DateTime.parse(
        json['gregorianBirthDateTime'] as String,
      ),
      birthTimeAccuracy: _enumByName(
        BirthTimeAccuracy.values,
        json['birthTimeAccuracy'] as String?,
        BirthTimeAccuracy.unknown,
      ),
      birthPlaceName: json['birthPlaceName'] as String?,
      lunarBirthDateText: json['lunarBirthDateText'] as String?,
      notes: json['notes'] as String?,
      isSelfProfile: json['isSelfProfile'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String get birthDateText {
    final date = gregorianBirthDateTime;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  static String? _blankToNull(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
