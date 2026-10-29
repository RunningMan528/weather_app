/// 模块：城市管理事件（city/presentation/bloc）
/// 依赖：本模块领域实体。
library;

import '../../domain/entities/city.dart';

sealed class CityManagerEvent {
  const CityManagerEvent();
}

/// 城市列表变化时重新读取各城市天气摘要。
final class CityManagerSummariesRequested extends CityManagerEvent {
  const CityManagerSummariesRequested(this.cities);

  final List<City> cities;
}
