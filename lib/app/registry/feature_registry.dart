import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 功能配置模型
class FeatureConfig {
  final String id;
  final String title;
  final String subtitle;
  final String categoryId;
  final String route;
  final String icon;
  final String status; // stable | beta | planned
  final String complexity; // simple | medium | complex | very_complex
  final String ritualType;
  final String engineType; // local | local_384 | local_100 | ai_assisted | placeholder
  final String? promptTemplateId;
  final bool requiresBirthInfo;
  final bool requiresQuestion;
  final bool supportsHistory;
  final bool supportsShare;

  const FeatureConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.categoryId,
    required this.route,
    required this.icon,
    required this.status,
    required this.complexity,
    required this.ritualType,
    required this.engineType,
    this.promptTemplateId,
    required this.requiresBirthInfo,
    required this.requiresQuestion,
    required this.supportsHistory,
    required this.supportsShare,
  });

  factory FeatureConfig.fromJson(Map<String, dynamic> json) {
    return FeatureConfig(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      categoryId: json['categoryId'] as String,
      route: json['route'] as String,
      icon: json['icon'] as String,
      status: json['status'] as String,
      complexity: json['complexity'] as String,
      ritualType: json['ritualType'] as String,
      engineType: json['engineType'] as String,
      promptTemplateId: json['promptTemplateId'] as String?,
      requiresBirthInfo: json['requiresBirthInfo'] as bool,
      requiresQuestion: json['requiresQuestion'] as bool,
      supportsHistory: json['supportsHistory'] as bool,
      supportsShare: json['supportsShare'] as bool,
    );
  }

  bool get isStable => status == 'stable';
  bool get isBeta => status == 'beta';
  bool get isPlanned => status == 'planned';
  bool get isAvailable => isStable || isBeta;
  bool get hasEngine => engineType != 'placeholder';
  bool get supportsAI => promptTemplateId != null;
}

/// 分类配置模型
class CategoryConfig {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String color;

  const CategoryConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.color,
  });

  factory CategoryConfig.fromJson(Map<String, dynamic> json) {
    return CategoryConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String,
      color: json['color'] as String,
    );
  }
}

/// 功能注册中心
class FeatureRegistry {
  final List<CategoryConfig> categories;
  final List<FeatureConfig> features;

  const FeatureRegistry({
    required this.categories,
    required this.features,
  });

  factory FeatureRegistry.fromJson(Map<String, dynamic> json) {
    return FeatureRegistry(
      categories: (json['categories'] as List)
          .map((e) => CategoryConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      features: (json['features'] as List)
          .map((e) => FeatureConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 按分类获取功能列表
  List<FeatureConfig> featuresByCategory(String categoryId) {
    return features.where((f) => f.categoryId == categoryId).toList();
  }

  /// 根据 ID 获取功能
  FeatureConfig? byId(String id) {
    try {
      return features.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 根据路由路径获取功能
  FeatureConfig? byRoute(String route) {
    try {
      return features.firstWhere((f) => f.route == route);
    } catch (_) {
      return null;
    }
  }

  /// 已可用的功能
  List<FeatureConfig> get availableFeatures {
    return features.where((f) => f.isAvailable).toList();
  }

  /// 稳定版功能
  List<FeatureConfig> get stableFeatures {
    return features.where((f) => f.isStable).toList();
  }

  /// 获取分类
  CategoryConfig? category(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Riverpod Provider：从 assets/data/features.json 加载注册中心
final featureRegistryProvider = FutureProvider<FeatureRegistry>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/data/features.json');
  final json = jsonDecode(jsonStr) as Map<String, dynamic>;
  return FeatureRegistry.fromJson(json);
});
