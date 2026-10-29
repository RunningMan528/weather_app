// 模块：令牌提供者（core/network）
// 作用：为鉴权拦截器提供访问令牌，避免 core 反向依赖 auth 模块。
// 依赖：纯 Dart。
// 实现方向：features/auth/data/datasources/session_token_provider.dart。

/// 访问令牌提供者。
abstract class TokenProvider {
  /// 当前访问令牌；未登录返回 null。
  String? get accessToken;
}
