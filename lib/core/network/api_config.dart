// 模块：网络配置（core/network）
// 作用：集中管理 baseUrl、超时与公共请求头，避免散落在各处的魔法值。
// 依赖：纯 Dart。
// 多环境说明：真实项目按 flavor 注入 dev/staging/prod 的 baseUrl，
//            本 Demo 的 baseUrl 只用于"假服务端"（请求被 MockInterceptor 拦截）。

/// 网络层配置。
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 15),
    this.defaultHeaders = const <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    this.enableLogging = true,
    this.maxRetryAttempts = 2,
  });

  /// 接口根地址。
  final String baseUrl;

  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  /// 公共请求头（渠道、语言、版本等通常也放这里）。
  final Map<String, String> defaultHeaders;

  /// 是否打印请求日志（生产环境建议关闭或降级为采样上报）。
  final bool enableLogging;

  /// 幂等请求的最大重试次数（0 表示不重试）。
  final int maxRetryAttempts;

  /// Demo 默认配置：baseUrl 是假的，请求由 MockApiAdapter 处理。
  static const ApiConfig demo = ApiConfig(baseUrl: 'https://api.demo.local/v1');
}
