/// 模块：加载天气用例（domain）
/// 作用：校验入参并调用仓库；forceRefresh 由下拉刷新触发。
/// 依赖：core/error/result、core/usecase、city/domain、本模块实体与仓库契约。
library;

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../city/domain/entities/city.dart';
import '../entities/weather.dart';
import '../repositories/weather_repository.dart';

class LoadWeatherParams {
  const LoadWeatherParams({required this.city, this.forceRefresh = false});

  final City city;

  /// true 表示下拉刷新：跳过缓存，强制请求网络。
  final bool forceRefresh;
}

class LoadWeatherUseCase extends UseCase<Weather, LoadWeatherParams> {
  const LoadWeatherUseCase(this._repository);

  final WeatherRepository _repository;

  @override
  Future<Result<Weather>> call(LoadWeatherParams params) {
    final city = params.city;
    if (!city.latitude.isFinite ||
        !city.longitude.isFinite ||
        city.latitude.abs() > 90 ||
        city.longitude.abs() > 180) {
      return Future<Result<Weather>>.value(
        const Err<Weather>(ValidationFailure('城市经纬度不合法')),
      );
    }
    return _repository.fetchWeather(city, forceRefresh: params.forceRefresh);
  }
}
