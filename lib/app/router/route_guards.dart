import 'package:go_router/go_router.dart';

/// 路由守卫 —— 可用于检查登录状态、隐私协议是否已同意等。
/// 当前 MVP 阶段直接放行，后续版本逐步启用。
class RouteGuards {
  /// 当前暂不拦截。
  static String? passThrough(GoRouterState state) {
    // MVP: 先放行
    return null;
  }
}
