/// 模块：城市天气摘要（city/domain）
/// 作用：城市管理页展示天气所需的**中性**摘要，不依赖天气 feature 的实体或 UI。
/// 依赖：纯 Dart + 本模块 City。
library;

import 'city.dart';

/// 城市卡片使用的天气类别（由天气 feature 的适配器映射 skycon 得到）。
enum CityWeatherCondition {
  sunny,
  cloudy,
  overcast,
  rain,
  snow,
  haze,
  fog,
  dust,
  unknown,
}

class CityWeatherSummary {
  const CityWeatherSummary({
    required this.city,
    this.temperature,
    this.maxTemperature,
    this.minTemperature,
    this.condition = CityWeatherCondition.unknown,
  });

  final City city;
  final int? temperature;
  final int? maxTemperature;
  final int? minTemperature;
  final CityWeatherCondition condition;

  bool get hasWeather =>
      temperature != null ||
      maxTemperature != null ||
      condition != CityWeatherCondition.unknown;
}
