/// 模块：天气状态（weather/presentation/bloc）
/// 依赖：core/error + city/domain + weather/domain。
library;

import '../../../../core/error/failure.dart';
import '../../../city/domain/entities/city.dart';
import '../../domain/entities/weather.dart';

enum WeatherStatus { initial, loading, ready, error }

class WeatherState {
  const WeatherState({
    this.status = WeatherStatus.initial,
    this.city,
    this.weather,
    this.failure,
  });

  final WeatherStatus status;
  final City? city;
  final Weather? weather;
  final Failure? failure;

  bool get hasData => weather != null;
}
