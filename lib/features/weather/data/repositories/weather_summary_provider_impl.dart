/// 模块：城市天气摘要适配器（weather/data）
/// 作用：实现 city/domain 声明的端口，把 Weather 实体映射成中性的 CityWeatherSummary。
/// 依赖：core/error/result、city/domain 契约、weather/domain 契约。
/// 依赖方向：weather/data → city/domain（允许），city 不反向依赖 weather。
library;

import '../../../../core/error/result.dart';
import '../../../city/domain/entities/city.dart';
import '../../../city/domain/entities/city_weather_summary.dart';
import '../../../city/domain/repositories/city_weather_summary_provider.dart';
import '../../domain/repositories/weather_repository.dart';

class WeatherSummaryProviderImpl implements CityWeatherSummaryProvider {
  WeatherSummaryProviderImpl(this._repository);

  final WeatherRepository _repository;

  @override
  Future<Result<CityWeatherSummary?>> summaryFor(City city) async {
    // 仓库策略：缓存优先；只有无缓存时才请求网络。
    final result = await _repository.fetchWeather(city);
    if (result.isErr) {
      return Err<CityWeatherSummary?>(result.failureOrNull!);
    }
    final weather = result.valueOrNull;
    if (weather == null) {
      return const Ok<CityWeatherSummary?>(null);
    }

    final realtime = weather.realtime;
    final forecasts = weather.daily?.forecasts;
    final today = forecasts != null && forecasts.isNotEmpty
        ? forecasts.first
        : null;
    return Ok<CityWeatherSummary?>(
      CityWeatherSummary(
        city: city,
        temperature: realtime?.temperature,
        maxTemperature: today?.maxTemperature,
        minTemperature: today?.minTemperature,
        condition: _conditionOf(realtime?.skycon),
      ),
    );
  }

  CityWeatherCondition _conditionOf(String? skycon) {
    switch (skycon) {
      case 'CLEAR_DAY':
      case 'CLEAR_NIGHT':
        return CityWeatherCondition.sunny;
      case 'PARTLY_CLOUDY_DAY':
      case 'PARTLY_CLOUDY_NIGHT':
        return CityWeatherCondition.cloudy;
      case 'CLOUDY':
      case 'WIND':
        return CityWeatherCondition.overcast;
      case 'LIGHT_RAIN':
      case 'MODERATE_RAIN':
      case 'HEAVY_RAIN':
      case 'STORM_RAIN':
        return CityWeatherCondition.rain;
      case 'LIGHT_SNOW':
      case 'MODERATE_SNOW':
      case 'HEAVY_SNOW':
      case 'STORM_SNOW':
        return CityWeatherCondition.snow;
      case 'LIGHT_HAZE':
      case 'MODERATE_HAZE':
      case 'HEAVY_HAZE':
        return CityWeatherCondition.haze;
      case 'FOG':
        return CityWeatherCondition.fog;
      case 'DUST':
      case 'SAND':
        return CityWeatherCondition.dust;
      default:
        return CityWeatherCondition.unknown;
    }
  }
}
