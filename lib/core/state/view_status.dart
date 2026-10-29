// 模块：页面状态枚举（core/state）
// 作用：统一“加载中 / 有数据 / 空列表 / 失败”四种页面态，让各模块的页面切换逻辑一致。
// 依赖：纯 Dart。
// 对应模板：等价于 Riverpod 的 AsyncValue，或 BLoC 中 state 的 status 字段。

/// 页面级状态。
enum ViewStatus {
  /// 尚未发起请求。
  initial,

  /// 首次加载中（展示骨架/loading）。
  loading,

  /// 有数据可展示。
  ready,

  /// 请求成功但数据为空（展示空态引导）。
  empty,

  /// 请求失败（展示错误文案 + 重试）。
  error,
}

/// 状态扩展：减少页面里的重复判断。
extension ViewStatusX on ViewStatus {
  /// 是否需要占据整页的加载态。
  bool get isFullScreenLoading =>
      this == ViewStatus.initial || this == ViewStatus.loading;

  /// 是否已有内容可展示（含空态）。
  bool get hasResolved => this == ViewStatus.ready || this == ViewStatus.empty;
}
