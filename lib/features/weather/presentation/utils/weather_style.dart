/// 模块：天气视觉映射（presentation/utils）
/// 作用：把领域层保留的彩云 skycon 字符串映射成描述、图标与动画背景枚举。
/// 依赖：Flutter、flutter_weather_bg。
/// 说明：颜色/图标属于展示关注点，因此不放进 domain。
library;

import 'package:flutter/material.dart';
import 'package:flutter_weather_bg/flutter_weather_bg.dart';

/// 生活指数类型。
enum LifeIndexType {
  ultraviolet,
  carWashing,
  dressing,
  comfort,
  coldRisk,
  typhoon,
}

class WeatherStyle {
  const WeatherStyle._();

  static const Map<String, String> _descriptions = <String, String>{
    'CLEAR_DAY': '晴',
    'CLEAR_NIGHT': '晴',
    'PARTLY_CLOUDY_DAY': '多云',
    'PARTLY_CLOUDY_NIGHT': '多云',
    'CLOUDY': '阴',
    'LIGHT_HAZE': '霾',
    'MODERATE_HAZE': '霾',
    'HEAVY_HAZE': '霾',
    'LIGHT_RAIN': '小雨',
    'MODERATE_RAIN': '中雨',
    'HEAVY_RAIN': '大雨',
    'STORM_RAIN': '暴雨',
    'FOG': '雾',
    'LIGHT_SNOW': '小雪',
    'MODERATE_SNOW': '中雪',
    'HEAVY_SNOW': '大雪',
    'STORM_SNOW': '暴雪',
    'DUST': '浮尘',
    'SAND': '沙尘',
    'WIND': '大风',
  };

  static const Map<String, WeatherType> _types = <String, WeatherType>{
    'CLEAR_DAY': WeatherType.sunny,
    'CLEAR_NIGHT': WeatherType.sunnyNight,
    'PARTLY_CLOUDY_DAY': WeatherType.cloudy,
    'PARTLY_CLOUDY_NIGHT': WeatherType.cloudyNight,
    'CLOUDY': WeatherType.overcast,
    'LIGHT_HAZE': WeatherType.hazy,
    'MODERATE_HAZE': WeatherType.hazy,
    'HEAVY_HAZE': WeatherType.hazy,
    'LIGHT_RAIN': WeatherType.lightRainy,
    'MODERATE_RAIN': WeatherType.middleRainy,
    'HEAVY_RAIN': WeatherType.heavyRainy,
    'STORM_RAIN': WeatherType.thunder,
    'FOG': WeatherType.foggy,
    'LIGHT_SNOW': WeatherType.lightSnow,
    'MODERATE_SNOW': WeatherType.middleSnow,
    'HEAVY_SNOW': WeatherType.heavySnow,
    'STORM_SNOW': WeatherType.heavySnow,
    'DUST': WeatherType.dusty,
    'SAND': WeatherType.dusty,
    'WIND': WeatherType.overcast,
  };

  /// skycon → 中文描述。
  static String description(String? skycon) => _descriptions[skycon] ?? '晴';

  /// skycon → 背景动画枚举。
  static WeatherType typeOf(String? skycon) =>
      _types[skycon] ?? WeatherType.sunny;

  /// 背景主色（用于毛玻璃卡片的半透明底色）。
  static List<Color> colors(WeatherType type) => WeatherUtil.getColor(type);

  static String iconFor(WeatherType type) {
    switch (type) {
      case WeatherType.sunny:
        return 'assets/images/weather/sunny.png';
      case WeatherType.sunnyNight:
        return 'assets/images/weather/sunny_night.png';
      case WeatherType.cloudy:
        return 'assets/images/weather/cloudy.png';
      case WeatherType.overcast:
        return 'assets/images/weather/overcast.png';
      case WeatherType.lightRainy:
        return 'assets/images/weather/small_rain.png';
      case WeatherType.middleRainy:
        return 'assets/images/weather/middle_rain.png';
      case WeatherType.heavyRainy:
      case WeatherType.thunder:
        return 'assets/images/weather/heavy_rain.png';
      case WeatherType.hazy:
      case WeatherType.foggy:
        return 'assets/images/weather/foggy.png';
      case WeatherType.lightSnow:
        return 'assets/images/weather/small_snow.png';
      case WeatherType.middleSnow:
        return 'assets/images/weather/middle_snow.png';
      case WeatherType.heavySnow:
        return 'assets/images/weather/heavy_snow.png';
      case WeatherType.dusty:
        return 'assets/images/weather/sandy.png';
      case WeatherType.cloudyNight:
        return 'assets/images/weather/cloudy_night.png';
    }
  }

  /// AQI 数值 → 中文等级。
  static String aqiDescription(int? aqi) {
    if (aqi == null) return '';
    if (aqi <= 50) return '优';
    if (aqi <= 100) return '良';
    if (aqi <= 150) return '轻度污染';
    if (aqi <= 200) return '中度污染';
    if (aqi <= 300) return '重度污染';
    return '严重污染';
  }

  static String lifeIndexIcon(LifeIndexType type) {
    switch (type) {
      case LifeIndexType.ultraviolet:
        return 'assets/images/ultraviolet.png';
      case LifeIndexType.carWashing:
        return 'assets/images/carWashing.png';
      case LifeIndexType.dressing:
        return 'assets/images/dressing.png';
      case LifeIndexType.comfort:
        return 'assets/images/comfort.png';
      case LifeIndexType.coldRisk:
        return 'assets/images/coldRisk.png';
      case LifeIndexType.typhoon:
        return 'assets/images/typhoon.png';
    }
  }

  static String lifeIndexLabel(LifeIndexType type) {
    switch (type) {
      case LifeIndexType.ultraviolet:
        return '紫外线';
      case LifeIndexType.carWashing:
        return '洗车指数';
      case LifeIndexType.dressing:
        return '穿衣指数';
      case LifeIndexType.comfort:
        return '舒适指数';
      case LifeIndexType.coldRisk:
        return '感冒指数';
      case LifeIndexType.typhoon:
        return '台风路径';
    }
  }
}
