// 模块：用例基类（core/usecase）
// 作用：统一 domain 层“一个用例一个类”的入口契约，让 presentation 只依赖用例，
//       不直接接触 repository 实现。
// 依赖：纯 Dart + core/error。
// 对应模板：UseCase 只做业务编排；取数、解析、缓存都放在 repository 实现里。

import '../error/result.dart';

/// 基础用例：入参统一包装成参数对象，便于后续扩展字段而不改动调用方。
///
/// ```dart
/// class LoadWeatherUseCase extends UseCase<Weather, LoadWeatherParams> {
///   const LoadWeatherUseCase(this._repository);
///   final WeatherRepository _repository;
///
///   @override
///   Future<Result<Weather>> call(LoadWeatherParams params) =>
///       _repository.fetchWeather(params.city);
/// }
/// ```
abstract class UseCase<T, P> {
  const UseCase();

  Future<Result<T>> call(P params);
}

/// 无参用例的占位参数：`call(const NoParams())`。
final class NoParams {
  const NoParams();

  @override
  String toString() => 'NoParams';
}
