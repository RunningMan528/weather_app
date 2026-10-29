/// 模块：天气事件（weather/presentation/bloc）
/// 依赖：city/domain 的城市实体（跨模块只依赖 domain 契约）。
library;

import '../../../city/domain/entities/city.dart';

sealed class WeatherEvent {
  const WeatherEvent();
}

/// 为指定城市加载天气。
final class WeatherRequested extends WeatherEvent {
  const WeatherRequested(this.city);

  final City city;
}

/// 重新加载当前城市天气（下拉刷新，强制走网络）。
final class WeatherRefreshed extends WeatherEvent {
  const WeatherRefreshed();
}

/// 城市列表变化时预读各城市本地缓存（不发网络）。
final class WeatherCachesPrepared extends WeatherEvent {
  const WeatherCachesPrepared(this.cities);

  final List<City> cities;
}
