/// 模块：天气图标缓存（presentation/utils）
/// 作用：CustomPainter 需要 dart:ui.Image 才能绘制天气图标。
/// 性能说明：
///   - ui.Image 不能跨 isolate 传递，因此必须在主 isolate 创建；
///   - 这里用 Future.wait 并发加载，并在首帧后由 app 触发 preload；
///   - 加载完成后 notifyListeners，图表通过 AnimatedBuilder 触发一次重绘。
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_weather_bg/flutter_weather_bg.dart';

import 'weather_style.dart';

class WeatherImageCache extends ChangeNotifier {
  WeatherImageCache._();

  static final WeatherImageCache instance = WeatherImageCache._();

  final Map<WeatherType, ui.Image> _images = <WeatherType, ui.Image>{};

  int _revision = 0;

  /// 每次有新图标加载完成时递增，供 CustomPainter 判断是否需要重绘。
  int get revision => _revision;

  Future<void> preload() async {
    final pending = <Future<void>>[];
    for (final type in WeatherType.values) {
      if (_images.containsKey(type)) continue;
      pending.add(_load(type));
    }
    if (pending.isEmpty) return;
    await Future.wait(pending);
    _revision++;
    notifyListeners();
  }

  Future<void> _load(WeatherType type) async {
    try {
      final data = await rootBundle.load(WeatherStyle.iconFor(type));
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _images[type] = frame.image;
      codec.dispose();
    } catch (_) {
      // 单个图标失败不影响其它图标与页面启动。
    }
  }

  ui.Image? imageOf(WeatherType type) => _images[type];
}
