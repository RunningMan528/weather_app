/// 模块：城市天气视觉映射（city/presentation/utils）
/// 作用：把中性的 CityWeatherCondition 映射为城市管理卡片的颜色/文案/图标。
/// 依赖：Flutter + 本模块领域实体。
library;

import 'package:flutter/material.dart';

import '../../domain/entities/city_weather_summary.dart';

class CityWeatherVisual {
  const CityWeatherVisual._();

  static String label(CityWeatherCondition condition) {
    switch (condition) {
      case CityWeatherCondition.sunny:
        return '晴';
      case CityWeatherCondition.cloudy:
        return '多云';
      case CityWeatherCondition.overcast:
        return '阴';
      case CityWeatherCondition.rain:
        return '雨';
      case CityWeatherCondition.snow:
        return '雪';
      case CityWeatherCondition.haze:
        return '霾';
      case CityWeatherCondition.fog:
        return '雾';
      case CityWeatherCondition.dust:
        return '浮尘';
      case CityWeatherCondition.unknown:
        return '';
    }
  }

  static List<Color> colors(CityWeatherCondition condition) {
    switch (condition) {
      case CityWeatherCondition.sunny:
        return const <Color>[Color(0xFF0071D1), Color(0xFF6DA6E4)];
      case CityWeatherCondition.cloudy:
        return const <Color>[Color(0xFF5C82C1), Color(0xFF95B1DB)];
      case CityWeatherCondition.overcast:
        return const <Color>[Color(0xFF8FA3C0), Color(0xFF8C9FB1)];
      case CityWeatherCondition.rain:
        return const <Color>[Color(0xFF3A4B65), Color(0xFF495764)];
      case CityWeatherCondition.snow:
        return const <Color>[Color(0xFF8595AD), Color(0xFF95A4BF)];
      case CityWeatherCondition.haze:
        return const <Color>[Color(0xFF989898), Color(0xFF4B4B4B)];
      case CityWeatherCondition.fog:
        return const <Color>[Color(0xFFA6B3C2), Color(0xFF737F88)];
      case CityWeatherCondition.dust:
        return const <Color>[Color(0xFFB99D79), Color(0xFF6C5635)];
      case CityWeatherCondition.unknown:
        return const <Color>[Color(0xFF0071D1), Color(0xFF6DA6E4)];
    }
  }

  static String icon(CityWeatherCondition condition) {
    switch (condition) {
      case CityWeatherCondition.sunny:
        return 'assets/images/weather/sunny.png';
      case CityWeatherCondition.cloudy:
        return 'assets/images/weather/cloudy.png';
      case CityWeatherCondition.overcast:
        return 'assets/images/weather/overcast.png';
      case CityWeatherCondition.rain:
        return 'assets/images/weather/middle_rain.png';
      case CityWeatherCondition.snow:
        return 'assets/images/weather/middle_snow.png';
      case CityWeatherCondition.haze:
      case CityWeatherCondition.fog:
        return 'assets/images/weather/foggy.png';
      case CityWeatherCondition.dust:
        return 'assets/images/weather/sandy.png';
      case CityWeatherCondition.unknown:
        return 'assets/images/weather/cloudy.png';
    }
  }
}
