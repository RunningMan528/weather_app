/// 模块：应用入口（main）
/// 作用：初始化绑定、校验配置、构建依赖图并启动应用。
/// 依赖：app/di、core/config。
/// 说明：入口只做装配，不包含任何业务逻辑。
library;

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di/dependency_module.dart';
import 'core/monitoring/monitoring_service.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const config = AppConfig.fromEnvironment;
  config.validate();
  debugPrint('[config] $config');

  final locator = buildDependencyGraph(config: config);
  final monitoring = locator.get<MonitoringService>();

  // Sentry 初始化最多等待 2 秒；超时/失败会降级并继续启动 App。
  await monitoring.init(appRunner: () => runApp(WeatherApp(locator: locator)));
}
