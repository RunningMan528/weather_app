/// 模块：空监控实现（core/monitoring）
/// 作用：Sentry 关闭或测试时使用，保证业务代码零改动。
/// 依赖：Flutter widgets + monitoring_service。
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'monitoring_service.dart';

class NoopMonitoringService implements MonitoringService {
  const NoopMonitoringService();

  @override
  Future<void> init({required FutureOr<void> Function() appRunner}) async {
    await appRunner();
  }

  @override
  List<NavigatorObserver> get navigatorObservers => const <NavigatorObserver>[];

  @override
  Future<void> captureException(
    Object error,
    StackTrace stackTrace, {
    String? message,
  }) async {}

  @override
  Future<void> captureMessage(
    String message, {
    MonitoringLevel level = MonitoringLevel.info,
  }) async {}

  @override
  Future<T> trace<T>({
    required String name,
    required String operation,
    required Future<T> Function() body,
  }) => body();

  @override
  void addBreadcrumb(String message, {String? category}) {}
}
