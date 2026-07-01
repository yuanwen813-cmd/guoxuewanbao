import 'package:go_router/go_router.dart';

/// 路由守卫 —— 可用于检查 API Key 是否已配置、隐私协议是否已同意等。
/// 当前 MVP 阶段直接放行，后续版本逐步启用。
class RouteGuards {
  /// 检查是否已配置 AI API Key（未配置则重定向到设置页）
  static String? apiKeyGuard(GoRouterState state) {
    // MVP: 先放行
    // const apiKeyConfigured = true;
    // if (!apiKeyConfigured) return '/settings/api-key';
    return null;
  }
}
