/// 模块：城市天气摘要端口（city/domain）
/// 作用：城市 feature 只声明"我需要能取到天气摘要"，具体实现由天气 feature 提供，
///       避免 city → weather 的反向依赖。
/// 依赖：纯 Dart + core/error + 本模块实体。
library;

import '../../../../core/error/result.dart';
import '../entities/city.dart';
import '../entities/city_weather_summary.dart';

abstract class CityWeatherSummaryProvider {
  Future<Result<CityWeatherSummary?>> summaryFor(City city);
}
