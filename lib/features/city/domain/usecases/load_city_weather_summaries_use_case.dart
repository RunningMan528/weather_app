/// 模块：批量读取城市天气摘要用例（city/domain）
/// 作用：对多个城市读取摘要时使用受限并发，避免无缓存城市同时发起过多网络请求。
/// 依赖：core/error/result、core/usecase、本模块实体与端口。
library;

import '../../../../core/error/result.dart';
import '../../../../core/usecase/use_case.dart';
import '../entities/city.dart';
import '../entities/city_weather_summary.dart';
import '../repositories/city_weather_summary_provider.dart';

class CityWeatherSummariesParams {
  const CityWeatherSummariesParams(this.cities);

  final List<City> cities;
}

class LoadCityWeatherSummariesUseCase
    extends UseCase<List<CityWeatherSummary>, CityWeatherSummariesParams> {
  const LoadCityWeatherSummariesUseCase(this._provider);

  final CityWeatherSummaryProvider _provider;

  /// 最多同时读取 3 个城市，兼顾加载速度与接口限流。
  static const int _maxConcurrent = 3;

  @override
  Future<Result<List<CityWeatherSummary>>> call(
    CityWeatherSummariesParams params,
  ) async {
    final cities = params.cities;
    if (cities.isEmpty) {
      return const Ok<List<CityWeatherSummary>>(<CityWeatherSummary>[]);
    }

    final summaries = List<CityWeatherSummary?>.filled(cities.length, null);
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final index = nextIndex;
        if (index >= cities.length) return;
        nextIndex++;
        final city = cities[index];
        final result = await _provider.summaryFor(city);
        summaries[index] = result.valueOrNull ?? CityWeatherSummary(city: city);
      }
    }

    final workerCount = cities.length < _maxConcurrent
        ? cities.length
        : _maxConcurrent;
    await Future.wait(
      List<Future<void>>.generate(workerCount, (_) => worker()),
    );

    return Ok<List<CityWeatherSummary>>(
      summaries.whereType<CityWeatherSummary>().toList(growable: false),
    );
  }
}
