/// 模块：读取缓存天气用例（domain）
/// 作用：切换城市时先读缓存，命中则不触发网络请求。
/// 依赖：core/error/result、core/usecase、city/domain、本模块实体与仓库契约。
library;

import '../../../../core/error/result.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../city/domain/entities/city.dart';
import '../entities/weather.dart';
import '../repositories/weather_repository.dart';

class LoadCachedWeatherParams {
  const LoadCachedWeatherParams(this.city);

  final City city;
}

class LoadCachedWeatherUseCase
    extends UseCase<Weather?, LoadCachedWeatherParams> {
  const LoadCachedWeatherUseCase(this._repository);

  final WeatherRepository _repository;

  @override
  Future<Result<Weather?>> call(LoadCachedWeatherParams params) =>
      _repository.readCachedWeather(params.city);
}
