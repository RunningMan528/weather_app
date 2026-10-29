// 模块：滚动更新门控（core/utils）
// 作用：滚动期间只记录"有更新"，停止滚动后统一刷新一次，避免高频数据在滚动中
//       触发额外 rebuild，导致掉帧。
// 适用：服务端推送型列表/页面（消息、行情列表、直播互动）。
// 不适用：交易价格等必须实时展示的数据；下单结果等必须立即反馈的交互。
// 依赖：纯 Dart（可用 dart run 直接验证），不依赖 Flutter。

import 'dart:async';

/// 滚动门控。
///
/// 用法：
/// ```dart
/// final gate = ScrollUpdateGate(onFlush: () => setState(() {}));
/// // 滚动开始/结束（由 NotificationListener<ScrollNotification> 转发）
/// gate.beginScroll();
/// gate.endScroll();
/// // 数据到达
/// gate.request();
/// ```
class ScrollUpdateGate {
  ScrollUpdateGate({
    required this.onFlush,
    this.debounce = const Duration(milliseconds: 120),
  });

  /// 停止滚动（并经 [debounce] 后）执行的回调。
  final void Function() onFlush;

  /// 停止后的去抖时间：避免惯性结束/回弹造成二次刷新。
  final Duration debounce;

  bool _scrolling = false;
  bool _pending = false;
  bool _disposed = false;
  Timer? _timer;

  /// 当前是否处于滚动中。
  bool get isScrolling => _scrolling;

  /// 是否有被推迟的更新。
  bool get hasPending => _pending;

  /// 滚动开始：取消防抖定时器，后续 [request] 只记账。
  void beginScroll() {
    if (_disposed) return;
    _scrolling = true;
    _timer?.cancel();
    _timer = null;
  }

  /// 滚动结束：延迟 [debounce] 后，若有挂起更新则统一刷新一次。
  void endScroll() {
    if (_disposed) return;
    _scrolling = false;
    _timer?.cancel();
    _timer = Timer(debounce, () {
      _timer = null;
      if (!_pending || _disposed) return;
      _pending = false;
      onFlush();
    });
  }

  /// 数据到达：滚动中或正在去抖时只记录；否则立即刷新。
  void request() {
    if (_disposed) return;
    if (_scrolling || _timer != null) {
      _pending = true;
      return;
    }
    onFlush();
  }

  /// 立即刷新（例如页面切走前、收到权威快照时）。
  void flushNow() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = null;
    _scrolling = false;
    if (!_pending) return;
    _pending = false;
    onFlush();
  }

  /// 释放：取消定时器并清空状态，之后所有调用都无效。
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _scrolling = false;
    _pending = false;
  }
}
