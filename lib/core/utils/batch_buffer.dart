// 模块：高频数据批量缓冲（core/utils）
// 作用：把短时间窗口内的多条消息合并为一次回调，降低 UI 刷新频率。
// 数据流：add() 入队 → 窗口到期 → onFlush(批次) → 调用方一次性更新状态。
// 资源管理：dispose() 取消防抖定时器，避免页面销毁后仍触发回调。
// 对应模板：订单簿增量这类“可以批量处理、但不能丢消息”的高频数据。

import 'dart:async';

/// 批量缓冲器：同一个窗口内的数据会被合并成一次回调。
///
/// 适合订单簿增量这类“可以批量处理、但不能丢消息”的场景。第一批数据到达时
/// 启动定时器，窗口到期后复制整个批次交给 [onFlush]，从而把多次状态更新合并。
class BatchBuffer<T> {
  BatchBuffer(this.interval, this.onFlush);

  final Duration interval;
  final void Function(List<T> batch) onFlush;

  final List<T> _pending = <T>[];
  Timer? _timer;

  bool get isEmpty => _pending.isEmpty;
  int get length => _pending.length;

  /// 追加一条数据；首个元素到达时启动定时器。
  void add(T item) {
    _pending.add(item);
    _timer ??= Timer(interval, _flush);
  }

  /// 定时窗口到期后复制并清空缓冲区，再统一交给 [onFlush]。
  ///
  /// 先复制再回调可以避免回调期间新增的数据被误清空。
  void _flush() {
    _timer = null;
    if (_pending.isEmpty) return;
    final batch = List<T>.from(_pending);
    _pending.clear();
    onFlush(batch);
  }

  /// 立即刷新当前缓冲内容，并取消尚未触发的定时器。
  void flushNow() {
    _timer?.cancel();
    _timer = null;
    _flush();
  }

  /// 丢弃尚未处理的增量：收到权威快照时调用，避免旧增量覆盖新快照。
  void clear() {
    _pending.clear();
  }

  /// 取消定时器并释放待处理数据，页面销毁时必须调用。
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending.clear();
  }
}
