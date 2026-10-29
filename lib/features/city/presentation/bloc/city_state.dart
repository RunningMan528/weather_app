/// 模块：城市状态（city/presentation/bloc）
/// 依赖：core/error + 本模块领域实体。
library;

import '../../../../core/error/failure.dart';
import '../../domain/entities/city.dart';

enum CityStatus { initial, loading, ready, error }

class CityState {
  const CityState({
    this.status = CityStatus.initial,
    this.savedCities = const <City>[],
    this.selectedCity,
    this.failure,
    this.usedFallbackCity = false,
    this.fallbackReason,
  });

  final CityStatus status;
  final List<City> savedCities;
  final City? selectedCity;
  final Failure? failure;

  /// 定位失败时使用了北京兜底，页面可据此提示。
  final bool usedFallbackCity;

  /// 定位失败的具体原因（权限、服务未开启、超时等）。
  final String? fallbackReason;

  int get selectedIndex {
    final selected = selectedCity;
    if (selected == null) return 0;
    final index = savedCities.indexWhere(
      (item) => item.cacheKey == selected.cacheKey,
    );
    return index < 0 ? 0 : index;
  }
}
