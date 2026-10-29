// 模块：统一错误模型（core/error）
// 作用：把 data 层可能出现的异常（网络、超时、鉴权、校验、缓存、服务端）收敛成
//       可分类、可展示、可埋点的领域错误，避免 Exception 直接穿透到 presentation。
// 依赖：纯 Dart，不 import Flutter，可被 core / domain / data 任意层引用。
// 对应模板：真实项目里 Failure 通常还会带 traceId、是否可重试、是否要上报等元信息。

/// 错误类别：UI 依据类别决定交互（重试 / 去登录 / 只提示）。
enum FailureKind {
  network,
  timeout,
  auth,
  validation,
  notFound,
  cache,
  server,
  unknown,
}

/// 领域失败：所有可预期错误的统一载体。
///
/// 用 sealed 类而不是字符串，是为了让上层可以用 switch 穷尽处理，
/// 编译器会在新增子类时提示所有需要更新的位置。
sealed class Failure {
  const Failure(
    this.message, {
    this.kind = FailureKind.unknown,
    this.code,
    this.cause,
  });

  /// 面向开发者的描述，用于日志与排查。
  final String message;

  /// 错误类别，决定 UI 交互。
  final FailureKind kind;

  /// 业务错误码：服务端返回的 code 或本地约定的错误码。
  final String? code;

  /// 原始异常对象，只用于日志，不直接展示给用户。
  final Object? cause;

  /// 是否值得给用户“重试”入口。
  bool get isRetryable =>
      kind == FailureKind.network ||
      kind == FailureKind.timeout ||
      kind == FailureKind.server;

  /// 是否需要把用户引导到登录页。
  bool get requiresLogin => kind == FailureKind.auth;

  /// 面向用户的兜底文案：页面优先使用业务自定义文案，没有时用这里。
  String get userMessage => switch (kind) {
    FailureKind.network => '网络连接不可用，请检查网络后重试',
    FailureKind.timeout => '请求超时，请稍后重试',
    FailureKind.auth => '登录状态已失效，请重新登录',
    FailureKind.validation => message,
    FailureKind.notFound => '内容不存在或已下线',
    FailureKind.cache => '本地数据读取失败',
    FailureKind.server => '服务暂时不可用，请稍后重试',
    FailureKind.unknown => '出现未知问题，请稍后重试',
  };

  @override
  String toString() => 'Failure(kind: $kind, code: $code, message: $message)';
}

/// 网络不可用（无连接、DNS 失败、连接被拒绝）。
final class NetworkFailure extends Failure {
  const NetworkFailure({String? message, super.code, super.cause})
    : super(message ?? '网络不可用', kind: FailureKind.network);
}

/// 请求超时。
final class TimeoutFailure extends Failure {
  const TimeoutFailure({String? message, super.code, super.cause})
    : super(message ?? '请求超时', kind: FailureKind.timeout);
}

/// 鉴权失败：token 失效、刷新失败、账号被禁用。
final class AuthFailure extends Failure {
  const AuthFailure({String? message, super.code, super.cause})
    : super(message ?? '登录状态已失效', kind: FailureKind.auth);
}

/// 入参校验失败：表单为空、格式错误、超出范围。
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, super.cause})
    : super(kind: FailureKind.validation);
}

/// 目标内容不存在。
final class NotFoundFailure extends Failure {
  const NotFoundFailure({String? message, super.code, super.cause})
    : super(message ?? '内容不存在', kind: FailureKind.notFound);
}

/// 本地缓存/本地存储失败。
final class CacheFailure extends Failure {
  const CacheFailure({String? message, super.code, super.cause})
    : super(message ?? '本地存储失败', kind: FailureKind.cache);
}

/// 服务端业务错误：HTTP 2xx 但业务 code 表示失败，或 5xx。
final class ServerFailure extends Failure {
  const ServerFailure({String? message, super.code, super.cause})
    : super(message ?? '服务端返回错误', kind: FailureKind.server);
}

/// 未归类错误（解析失败、未预期异常）。
final class UnknownFailure extends Failure {
  const UnknownFailure({String? message, super.code, super.cause})
    : super(message ?? '未知错误');
}
