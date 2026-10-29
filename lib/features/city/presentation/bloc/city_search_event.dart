/// 模块：城市搜索事件（presentation/bloc）
/// 依赖：纯 Dart。
library;

sealed class CitySearchEvent {
  const CitySearchEvent();
}

/// 关键词变化（页面侧做 400ms 防抖）。
final class CitySearchKeywordChanged extends CitySearchEvent {
  const CitySearchKeywordChanged(this.keyword);

  final String keyword;
}
