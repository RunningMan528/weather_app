/// 模块：城市管理状态（city/presentation/bloc）
/// 依赖：core/error + 本模块领域实体。
library;

import '../../../../core/error/failure.dart';
import '../../domain/entities/city_weather_summary.dart';

class CityManagerState {
  const CityManagerState({
    this.summaries = const <CityWeatherSummary>[],
    this.isLoading = false,
    this.failure,
  });

  final List<CityWeatherSummary> summaries;
  final bool isLoading;
  final Failure? failure;
}
