/// 模块：应用根组件（app）
/// 作用：装配 MaterialApp（路由、依赖作用域）与应用级 CityBloc / WeatherBloc。
/// 依赖：flutter_bloc、ServiceLocator、AppRouter。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/city/presentation/bloc/city_bloc.dart';
import '../features/city/presentation/bloc/city_event.dart';
import '../core/monitoring/monitoring_service.dart';
import '../features/weather/presentation/bloc/weather_bloc.dart';
import '../features/weather/presentation/utils/weather_image_cache.dart';
import 'di/app_scope.dart';
import 'di/service_locator.dart';
import 'router/app_router.dart';
import 'router/app_routes.dart';

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key, required this.locator});

  final ServiceLocator locator;

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  late final AppRouter _router = AppRouter(widget.locator);
  late final CityBloc _cityBloc;
  late final WeatherBloc _weatherBloc;
  late final MonitoringService _monitoring;

  @override
  void initState() {
    super.initState();
    // 应用级 bloc：城市是唯一状态源；天气 bloc 由首页监听城市变化后触发。
    _cityBloc = widget.locator.get<CityBloc>();
    _weatherBloc = widget.locator.get<WeatherBloc>();
    _monitoring = widget.locator.get<MonitoringService>();

    // 首帧先渲染轻量 loading，再启动定位/缓存读取与图标预加载，
    // 避免真机首次构建直接进入较重的天气内容导致长时间白屏。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cityBloc.add(const CityStarted());
      unawaited(
        _monitoring.trace<void>(
          name: 'weather_icon_preload',
          operation: 'asset.load',
          body: WeatherImageCache.instance.preload,
        ),
      );
    });
  }

  @override
  void dispose() {
    unawaited(_weatherBloc.close());
    unawaited(_cityBloc.close());
    unawaited(widget.locator.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      locator: widget.locator,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CityBloc>.value(value: _cityBloc),
          BlocProvider<WeatherBloc>.value(value: _weatherBloc),
        ],
        child: MaterialApp(
          title: '简悦天气',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true),
          navigatorObservers: _monitoring.navigatorObservers,
          onGenerateRoute: _router.onGenerateRoute,
          initialRoute: AppRoutes.home,
        ),
      ),
    );
  }
}
