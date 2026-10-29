/// 模块：天气动态背景（presentation/widgets）
/// 作用：根据当前天气类型渲染 flutter_weather_bg 的动画场景。
/// 依赖：Flutter + flutter_weather_bg。
library;

import 'package:flutter/material.dart';
import 'package:flutter_weather_bg/flutter_weather_bg.dart';

class WeatherMainBg extends StatelessWidget {
  const WeatherMainBg({super.key, required this.weatherType});

  final WeatherType weatherType;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return WeatherBg(
      weatherType: weatherType,
      width: size.width,
      height: size.height,
    );
  }
}
