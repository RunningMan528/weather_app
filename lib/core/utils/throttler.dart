// 模块：节流器（core/utils）
// 作用：固定周期内只放行一次回调，丢弃中间的高频触发。
// 适用：只关心最新值的场景，例如 Ticker 文案刷新；不保证每条消息都被处理。
// 与 BatchBuffer 的区别：节流丢弃中间值，批处理保留全部值。

import 'dart:async';

/// 节流器：固定周期内只执行一次回调，中间触发会被合并成一次尾调用。
class Throttler {
  Throttler(this.interval, this.onTick);

  final Duration interval;
  final void Function() onTick;

  Timer? _timer;
  bool _pending = false;

  /// 触发一次节流更新。
  ///
  /// 如果当前周期仍在计时，只记录 pending；计时结束后再执行一次最新回调。
  void trigger() {
    if (_timer != null) {
      _pending = true;
      return;
    }
    _timer = Timer(interval, () {
      _timer = null;
      onTick();
      if (_pending) {
        _pending = false;
        trigger();
      }
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending = false;
  }
}
