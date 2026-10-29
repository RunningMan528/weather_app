/// 模块：监控抽象（core/monitoring）
/// 作用：为业务与 app 层提供稳定的监控契约，屏蔽 Sentry 等具体实现。
/// 可插拔：
///   - 生产使用 SentryMonitoringService；
///   - 测试/关闭时使用 NoopMonitoringService；
///   - 业务代码不直接 import sentry。
/// 依赖：Flutter（NavigatorObserver）+ core/error 无关。
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

enum MonitoringLevel { debug, info, warning, error, fatal }

abstract class MonitoringService {
  /// 初始化监控；[appRunner] 必须在监控初始化完成后启动应用。
  Future<void> init({required FutureOr<void> Function() appRunner});

  /// 供 MaterialApp 使用的路由观察器（性能监控按页面生成 transaction）。
  List<NavigatorObserver> get navigatorObservers;

  Future<void> captureException(
    Object error,
    StackTrace stackTrace, {
    String? message,
  });

  Future<void> captureMessage(
    String message, {
    MonitoringLevel level = MonitoringLevel.info,
  });

  /// 可选的自定义性能 span；未初始化时直接执行 [body]。
  Future<T> trace<T>({
    required String name,
    required String operation,
    required Future<T> Function() body,
  });

  void addBreadcrumb(String message, {String? category});
}
