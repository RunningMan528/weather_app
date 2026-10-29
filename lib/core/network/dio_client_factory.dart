// 模块：dio 装配（core/network）
// 作用：集中创建配置好的 Dio 实例（超时、公共头、拦截器、可替换的适配器）。
// 依赖：dio + ApiConfig + 三个拦截器。
// 拦截器顺序说明：Retry 先加入（错误先到它），鉴权其次，日志最后——
//   这样日志能记录每一次实际发送（含重试）。
// 适配器替换点：传入 MockApiAdapter 即为"假服务端"；传 null 走真实网络。

import 'package:dio/dio.dart';

import 'api_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'token_provider.dart';

/// 创建并配置 Dio。
Dio buildDio({
  required ApiConfig config,
  required TokenProvider tokenProvider,
  HttpClientAdapter? adapter,
  void Function()? onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.sendTimeout,
      headers: config.defaultHeaders,
      // 让 4xx/5xx 也走 DioException，便于统一映射 Failure。
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  );

  if (adapter != null) {
    dio.httpClientAdapter = adapter;
  }

  if (config.maxRetryAttempts > 0) {
    dio.interceptors.add(
      RetryInterceptor(dio: dio, maxAttempts: config.maxRetryAttempts),
    );
  }
  dio.interceptors.add(
    AuthInterceptor(
      tokenProvider: tokenProvider,
      onUnauthorized: onUnauthorized,
    ),
  );
  if (config.enableLogging) {
    dio.interceptors.add(LoggingInterceptor());
  }

  return dio;
}
