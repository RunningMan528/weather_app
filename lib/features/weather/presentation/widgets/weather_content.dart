/// 模块：天气内容区（weather/presentation/widgets）
/// 作用：首页的可滚动天气内容，供 app 组合层直接复用。
/// 依赖：Flutter + 本模块实体/组件。
library;

import 'package:flutter/material.dart';

import '../../domain/entities/weather.dart';
import '../utils/weather_dimen.dart';
import 'aqi_chart_view.dart';
import 'day_forecast_view.dart';
import 'hour_forecast_view.dart';
import 'life_index_view.dart';
import 'multi_day_forecast_view.dart';
import 'realtime_detail_view.dart';
import 'realtime_view.dart';

class WeatherContent extends StatelessWidget {
  const WeatherContent({
    super.key,
    required this.weather,
    required this.onRefresh,
  });

  final Weather weather;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.white,
      backgroundColor: Colors.black26,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: WeatherDimen.pageHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RealtimeView(weather: weather),
            AqiChartView(weather: weather),
            const SizedBox(height: WeatherDimen.sectionGap),
            DayForecastView(weather: weather),
            const SizedBox(height: WeatherDimen.sectionGap),
            MultiDayForecastView(weather: weather, height: 360),
            const SizedBox(height: WeatherDimen.sectionGap),
            HourForecastView(weather: weather),
            const SizedBox(height: WeatherDimen.largeSectionGap),
            RealtimeDetailView(weather: weather),
            const SizedBox(height: WeatherDimen.largeSectionGap),
            LifeIndexView(weather: weather),
            const SizedBox(height: 16),
            const _WeatherFooter(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _WeatherFooter extends StatelessWidget {
  const _WeatherFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/caiyun.png',
          width: 36,
          height: 36,
          color: Colors.white54,
        ),
        const SizedBox(width: 8),
        const Text('数据来自彩云科技', style: TextStyle(color: Colors.white54)),
      ],
    );
  }
}
