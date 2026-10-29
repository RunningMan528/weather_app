/// 模块：构建期配置（core/config）
/// 作用：集中管理天气接口、高德 Key、Sentry 监控与日志开关。
/// 依赖：纯 Dart。
/// 环境隔离：
///   - APP_ENV：dev / qa / prod（构建档位）；
///   - SENTRY_ENVIRONMENT：development / test / production（Sentry 环境）；
///   - 配置文件：config/dev.json、config/qa.json、config/prod.json。
/// 约束：
///   1) 所有字段 const，可作为 composition root 的默认参数；
///   2) 启动时调用 [validate]，配置非法立即失败；
///   3) 新增配置项时同步修改全部 config/*.json。
library;

class AppConfig {
  const AppConfig({
    required this.env,
    required this.caiyunBaseUrl,
    required this.amapBaseUrl,
    required this.amapKey,
    required this.enableHttpLogging,
    required this.sentryDsn,
    required this.sentryEnvironment,
    required this.sentryEnabled,
    required this.sentryDebug,
    required this.sentryTracesSampleRatePercent,
  });

  static const fromEnvironment = AppConfig(
    env: String.fromEnvironment('APP_ENV', defaultValue: 'qa'),
    caiyunBaseUrl: String.fromEnvironment(
      'CAIYUN_BASE_URL',
      defaultValue: 'https://api.caiyunapp.com/v2.5/1swIXYicOc3JzdO5/',
    ),
    amapBaseUrl: String.fromEnvironment(
      'AMAP_BASE_URL',
      defaultValue: 'https://restapi.amap.com/v3',
    ),
    amapKey: String.fromEnvironment(
      'AMAP_KEY',
      defaultValue: 'caceb7c5a7360c22b0375af4d8ba24a7',
    ),
    enableHttpLogging: bool.fromEnvironment(
      'ENABLE_HTTP_LOGGING',
      defaultValue: true,
    ),
    sentryDsn: String.fromEnvironment(
      'SENTRY_DSN',
      defaultValue: 'https://b043798eec7f3a8fa296fd3ea737a01d@o4512337269358592.ingest.us.sentry.io/4512337277157376',
    ),
    sentryEnvironment: String.fromEnvironment(
      'SENTRY_ENVIRONMENT',
      defaultValue: 'development',
    ),
    sentryEnabled: bool.fromEnvironment('SENTRY_ENABLED', defaultValue: true),
    sentryDebug: bool.fromEnvironment('SENTRY_DEBUG', defaultValue: false),
    sentryTracesSampleRatePercent: int.fromEnvironment(
      'SENTRY_TRACES_SAMPLE_RATE_PERCENT',
      defaultValue: 100,
    ),
  );

  /// 环境档位：dev / qa / prod。
  final String env;

  /// 彩云天气根地址，必须以 `/` 结尾。
  final String caiyunBaseUrl;

  /// 高德开放平台根地址，例如 `https://restapi.amap.com/v3`。
  final String amapBaseUrl;

  /// 高德 Web 服务 Key。
  final String amapKey;

  /// 是否打印 HTTP 日志。
  final bool enableHttpLogging;

  /// Sentry DSN（客户端公钥，可放在构建配置中）。
  final String sentryDsn;

  /// Sentry 环境：development / test / production。
  final String sentryEnvironment;

  /// 是否启用 Sentry；关闭后走 NoopMonitoringService。
  final bool sentryEnabled;

  /// Sentry 自身调试日志。
  final bool sentryDebug;

  /// 性能追踪采样百分比：0–100。
  final int sentryTracesSampleRatePercent;

  /// 转换为主 SDK 需要的 0.0–1.0 采样率。
  double get sentryTracesSampleRate =>
      (sentryTracesSampleRatePercent.clamp(0, 100)) / 100;

  void validate() {
    if (env.trim().isEmpty) {
      throw StateError('APP_ENV 不能为空（检查 config/*.json）');
    }
    _requireUrl(caiyunBaseUrl, 'CAIYUN_BASE_URL');
    _requireUrl(amapBaseUrl, 'AMAP_BASE_URL');
    if (!caiyunBaseUrl.endsWith('/')) {
      throw StateError('CAIYUN_BASE_URL 必须以 / 结尾：$caiyunBaseUrl');
    }
    if (amapKey.trim().isEmpty) {
      throw StateError('AMAP_KEY 不能为空（检查 config/*.json）');
    }
    if (sentryEnabled) {
      _validateSentry();
    }
  }

  void _validateSentry() {
    if (sentryDsn.trim().isEmpty) {
      throw StateError('SENTRY_DSN 不能为空（检查 config/*.json）');
    }
    final uri = Uri.tryParse(sentryDsn);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw StateError('SENTRY_DSN 不是合法的 HTTPS DSN');
    }
    const allowedEnvironments = <String>{'development', 'test', 'production'};
    if (!allowedEnvironments.contains(sentryEnvironment)) {
      throw StateError(
        'SENTRY_ENVIRONMENT 必须是 development / test / production，'
        '当前为：$sentryEnvironment',
      );
    }
    if (sentryTracesSampleRatePercent < 0 ||
        sentryTracesSampleRatePercent > 100) {
      throw StateError(
        'SENTRY_TRACES_SAMPLE_RATE_PERCENT 必须在 0–100 之间，'
        '当前为：$sentryTracesSampleRatePercent',
      );
    }
  }

  static void _requireUrl(String value, String name) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.host.isEmpty ||
        !const <String>{'http', 'https'}.contains(uri.scheme.toLowerCase())) {
      throw StateError('$name 不是合法 HTTP(S) 地址：$value');
    }
  }

  @override
  String toString() =>
      'AppConfig(env: $env, caiyun: $caiyunBaseUrl, amap: $amapBaseUrl, '
      'sentryEnv: $sentryEnvironment, sentryEnabled: $sentryEnabled, '
      'sentryTrace: $sentryTracesSampleRatePercent%, '
      'logging: $enableHttpLogging)';
}
