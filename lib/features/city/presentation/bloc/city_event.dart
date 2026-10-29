/// 模块：城市事件（city/presentation/bloc）
/// 依赖：本模块领域实体。
library;

import '../../domain/entities/city.dart';

sealed class CityEvent {
  const CityEvent();
}

/// 首次进入：读取已保存城市 + 定位当前城市。
final class CityStarted extends CityEvent {
  const CityStarted();
}

/// 重新定位并用新定位城市替换旧的定位城市。
final class CityRelocated extends CityEvent {
  const CityRelocated();
}

/// 切换选中城市。
final class CitySelected extends CityEvent {
  const CitySelected(this.city);

  final City city;
}

/// 新增城市（已存在则直接选中）。
final class CityAdded extends CityEvent {
  const CityAdded(this.city);

  final City city;
}

/// 删除城市（定位城市不可删除）。
final class CityRemoved extends CityEvent {
  const CityRemoved(this.city);

  final City city;
}
