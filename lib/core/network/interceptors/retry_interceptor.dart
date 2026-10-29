// 模块：重试拦截器（core/network/interceptors）
// 作用：对"幂等且可恢复"的失败做有限重试（超时、连接失败、5xx），避免用户手动重试。
// 依赖：dio。
// 安全边界：
//   1) 只重试幂等方法（GET/HEAD），写操作重试必须有服务端幂等保证（如幂等键）；
//   2) 重试次数有上限，且带退避，避免放大故障（惊群）；
//   3) 业务错误（4xx 业务码）不重试——重试也不会成功。

import 'package:dio/dio.dart';

/// 重试拦截器。
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxAttempts = 2,
    this.backoff = const Duration(milliseconds: 300),
  });

  final Dio dio;

  /// 最大重试次数（不含首次请求）。
  final int maxAttempts;

  /// 退避基数：第 n 次重试等待 backoff * n。
  final Duration backoff;

  static const String _attemptKey = 'retry_attempt';
  static const Set<String> _idempotentMethods = {'GET', 'HEAD', 'OPTIONS'};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;

    if (!_shouldRetry(err, attempt)) return handler.next(err);

    options.extra[_attemptKey] = attempt + 1;
    await Future<void>.delayed(backoff * (attempt + 1));

    try {
      final response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  /// 判断是否值得重试。
  bool _shouldRetry(DioException err, int attempt) {
    if (attempt >= maxAttempts) return false;
    if (!_idempotentMethods.contains(err.requestOptions.method.toUpperCase())) {
      return false;
    }
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      DioExceptionType.badResponse => (err.response?.statusCode ?? 0) >= 500,
      _ => false,
    };
  }
}
