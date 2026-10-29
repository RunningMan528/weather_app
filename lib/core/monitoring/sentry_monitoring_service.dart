/// 模块：Sentry 监控实现（core/monitoring）
/// 作用：唯一直接依赖 Sentry 的地方；对业务层只暴露 MonitoringService 抽象。
/// 能力：
///   - 自动错误捕获（Sentry Flutter 默认集成）；
///   - 路由/启动性能追踪（tracesSampleRate + SentryNavigatorObserver）；
///   - logging 集成（sentry_logging）；
///   - 可选自定义 span（trace）。
/// 环境隔离：DSN / environment / 采样率均由 AppConfig 注入。
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_logging/sentry_logging.dart';

import '../config/app_config.dart';
import 'monitoring_service.dart';

class SentryMonitoringService implements MonitoringService {
  SentryMonitoringService(this._config);

  final AppConfig _config;

  bool _initialized = false;

  List<NavigatorObserver> _navigatorObservers = const <NavigatorObserver>[];

  @override
  List<NavigatorObserver> get navigatorObservers =>
      _initialized ? _navigatorObservers : const <NavigatorObserver>[];

  void _configureNavigatorObserver() {
    try {
      final observer = SentryNavigatorObserver(enableAutoTransactions: true);
      _navigatorObservers = <NavigatorObserver>[observer];
    } catch (error) {
      debugPrint(
        '[monitoring] Failed to create SentryNavigatorObserver: $error',
      );
      _navigatorObservers = const <NavigatorObserver>[];
    }
  }

  /// Sentry 原生初始化上限；超时后优先保证 App 启动。
  static const Duration _initTimeout = Duration(seconds: 2);

  @override
  Future<void> init({required FutureOr<void> Function() appRunner}) async {
    if (!_config.sentryEnabled) {
      await appRunner();
      return;
    }

    var appRunnerExecuted = false;
    Future<void> runAppOnce() async {
      if (appRunnerExecuted) return;
      appRunnerExecuted = true;
      await appRunner();
    }

    Future<void>? initFuture;
    try {
      initFuture = SentryFlutter.init(
        (options) {
          options.dsn = _config.sentryDsn;
          options.environment = _config.sentryEnvironment;
          options.tracesSampleRate = _config.sentryTracesSampleRate;
          options.debug = _config.sentryDebug;

          // 稳定性与隐私基线
          options.attachStacktrace = true;
          options.sendDefaultPii = false;
          options.maxBreadcrumbs = 50;

          // 自动会话、生命周期与性能
          options.enableAutoSessionTracking = true;
          options.enableAutoNativeBreadcrumbs = true;
          options.enableAppLifecycleBreadcrumbs = true;
          options.enableUserInteractionBreadcrumbs = true;
          options.enableAutoPerformanceTracing = true;

          // 把 logging 包日志接入 Sentry（面包屑 + SEVERE 事件）
          options.addIntegration(LoggingIntegration());
        },
        appRunner: () async {
          _initialized = true;
          _configureNavigatorObserver();
          await runAppOnce();
        },
      );
      await initFuture.timeout(_initTimeout);
    } on TimeoutException {
      // 常见于 iOS 原生插件未正确链接、首次 SPM/原生初始化过慢。
      // 监控不能阻塞 App：先 runApp，Sentry 后续完成/失败都不影响启动。
      _initialized = false;
      debugPrint(
        '[monitoring] Sentry init timed out after '
        '${_initTimeout.inSeconds}s; starting app without Sentry',
      );
      await runAppOnce();
      final pending = initFuture;
      if (pending != null) {
        unawaited(
          pending.catchError((Object error, StackTrace stackTrace) {
            debugPrint('[monitoring] Sentry init failed after timeout: $error');
          }),
        );
      }
    } catch (error, stackTrace) {
      _initialized = false;
      debugPrint('[monitoring] Sentry init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await runAppOnce();
    }
  }

  @override
  Future<void> captureException(
    Object error,
    StackTrace stackTrace, {
    String? message,
  }) async {
    if (!_initialized) return;
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      message: message == null ? null : SentryMessage(message),
    );
  }

  @override
  Future<void> captureMessage(
    String message, {
    MonitoringLevel level = MonitoringLevel.info,
  }) async {
    if (!_initialized) return;
    await Sentry.captureMessage(message, level: _toSentryLevel(level));
  }

  @override
  Future<T> trace<T>({
    required String name,
    required String operation,
    required Future<T> Function() body,
  }) async {
    if (!_initialized) return body();

    final transaction = Sentry.startTransaction(name, operation);
    try {
      final result = await body();
      transaction.status = const SpanStatus.ok();
      return result;
    } catch (error) {
      transaction.throwable = error;
      transaction.status = const SpanStatus.internalError();
      rethrow;
    } finally {
      await transaction.finish();
    }
  }

  @override
  void addBreadcrumb(String message, {String? category}) {
    if (!_initialized) return;
    unawaited(
      Sentry.addBreadcrumb(
        Breadcrumb(message: message, category: category ?? 'app'),
      ),
    );
  }

  SentryLevel _toSentryLevel(MonitoringLevel level) => switch (level) {
    MonitoringLevel.debug => SentryLevel.debug,
    MonitoringLevel.info => SentryLevel.info,
    MonitoringLevel.warning => SentryLevel.warning,
    MonitoringLevel.error => SentryLevel.error,
    MonitoringLevel.fatal => SentryLevel.fatal,
  };
}
