/// 模块：多天趋势图（presentation/widgets）
/// 作用：横向绘制多天温度曲线、昼夜天气图标与描述。
/// 依赖：Flutter + 本模块实体/样式/图片缓存。
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_weather_bg/flutter_weather_bg.dart';

import '../../domain/entities/weather.dart';
import '../utils/text_painter_utils.dart';
import '../utils/time_formatter.dart';
import '../utils/weather_image_cache.dart';
import '../utils/weather_style.dart';

class MultiDayForecastView extends StatelessWidget {
  const MultiDayForecastView({super.key, required this.weather, this.height});

  final Weather weather;

  /// 为空时按弹层高度（屏幕 55%）渲染；主页内嵌时可传固定高度。
  final double? height;

  @override
  Widget build(BuildContext context) {
    final forecasts = weather.daily?.forecasts ?? const <DailyForecast>[];
    if (forecasts.isEmpty) {
      return const Center(
        child: Text('暂无多天预报', style: TextStyle(color: Colors.white70)),
      );
    }
    final resolvedHeight = height ?? MediaQuery.sizeOf(context).height * 0.55;
    return SizedBox(
      height: resolvedHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: AnimatedBuilder(
          animation: WeatherImageCache.instance,
          builder: (context, _) => CustomPaint(
            painter: DailyForecastChartPainter(
              forecasts,
              height: resolvedHeight,
              imageRevision: WeatherImageCache.instance.revision,
            ),
            size: Size(forecasts.length * 100, resolvedHeight),
          ),
        ),
      ),
    );
  }
}

class DailyForecastChartPainter extends CustomPainter {
  DailyForecastChartPainter(
    this.data, {
    required this.height,
    required this.imageRevision,
  });

  final List<DailyForecast> data;
  final double height;
  final int imageRevision;

  static const double _mainTextSize = 14;
  static const double _subTextSize = 10;
  static const double _margin1 = 20;
  static const double _margin2 = 15;
  static const double _margin3 = 30;
  static const double _tempTextSize = 14;
  static const double _iconSize = 30;
  static const double _itemWidth = 100;

  late final int _topMaxTemp = data.map((e) => e.maxTemperature).reduce(max);
  late final int _topMinTemp = data.map((e) => e.maxTemperature).reduce(min);
  late final int _bottomMaxTemp = data.map((e) => e.minTemperature).reduce(max);
  late final int _bottomMinTemp = data.map((e) => e.minTemperature).reduce(min);

  late final double _lineHeight = max(
    8,
    (height -
            _mainTextSize * 3 -
            _subTextSize * 2 -
            _margin1 * 2 -
            _margin2 * 4 -
            _margin3 * 4 -
            _tempTextSize * 2 -
            _iconSize * 2) /
        2,
  );

  late final double _topLineStartY =
      _margin2 * 2 +
      _margin3 * 2 +
      _margin1 +
      _mainTextSize * 2 +
      _tempTextSize +
      _subTextSize +
      _iconSize;
  late final double _topLineEndY = _topLineStartY + _lineHeight;
  late final double _bottomLineStartY = _topLineEndY + _margin1;
  late final double _bottomLineEndY = _bottomLineStartY + _lineHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final topPath = Path();
    final bottomPath = Path();
    var startX = _itemWidth / 2;

    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final timeParagraph = TextPainterUtils.paragraph(
        TimeFormatter.weatherDayLabel(item.date),
        _mainTextSize,
        maxWidth: _itemWidth,
      );
      canvas.drawParagraph(
        timeParagraph,
        Offset(startX - timeParagraph.width / 2, _margin3),
      );

      final dateY = _margin3 + _margin1 + _mainTextSize;
      final dateParagraph = TextPainterUtils.paragraph(
        TimeFormatter.dayMonthLabel(item.date),
        _subTextSize,
        maxWidth: _itemWidth,
      );
      canvas.drawParagraph(
        dateParagraph,
        Offset(startX - dateParagraph.width / 2, dateY),
      );

      final dayIconY = dateY + _margin3;
      _drawIcon(
        canvas,
        WeatherStyle.typeOf(item.daySkycon),
        Offset(startX, dayIconY + _iconSize / 2),
      );

      final dayDescY = dayIconY + _iconSize + _margin2;
      final dayParagraph = TextPainterUtils.paragraph(
        WeatherStyle.description(item.daySkycon),
        _mainTextSize,
        maxWidth: _itemWidth,
      );
      canvas.drawParagraph(
        dayParagraph,
        Offset(startX - dayParagraph.width / 2, dayDescY),
      );

      final nightIconY = _bottomLineEndY + _tempTextSize + _margin2;
      _drawIcon(
        canvas,
        WeatherStyle.typeOf(item.nightSkycon),
        Offset(startX, nightIconY + _iconSize / 2),
      );

      final nightDescY = nightIconY + _iconSize + _margin2;
      final nightParagraph = TextPainterUtils.paragraph(
        WeatherStyle.description(item.nightSkycon),
        _mainTextSize,
        maxWidth: _itemWidth,
      );
      canvas.drawParagraph(
        nightParagraph,
        Offset(startX - nightParagraph.width / 2, nightDescY),
      );

      paint
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final topOffset = Offset(startX, _topLineY(item.maxTemperature));
      final bottomOffset = Offset(startX, _bottomLineY(item.minTemperature));
      canvas.drawCircle(topOffset, 3, paint);
      canvas.drawCircle(bottomOffset, 3, paint);

      _drawTemperatureLabel(
        canvas,
        '${item.maxTemperature}°',
        topOffset,
        above: true,
      );
      _drawTemperatureLabel(
        canvas,
        '${item.minTemperature}°',
        bottomOffset,
        above: false,
      );

      if (i == 0) {
        topPath.moveTo(topOffset.dx, topOffset.dy);
        bottomPath.moveTo(bottomOffset.dx, bottomOffset.dy);
      } else {
        topPath.lineTo(topOffset.dx, topOffset.dy);
        bottomPath.lineTo(bottomOffset.dx, bottomOffset.dy);
      }
      startX += _itemWidth;
    }

    paint
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(topPath, paint);
    canvas.drawPath(bottomPath, paint);
  }

  void _drawIcon(Canvas canvas, WeatherType type, Offset center) {
    final image = WeatherImageCache.instance.imageOf(type);
    if (image == null) return;
    final scale = _iconSize / image.width;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.drawImage(
      image,
      Offset(-image.width / 2, -image.height / 2),
      Paint(),
    );
    canvas.restore();
  }

  void _drawTemperatureLabel(
    Canvas canvas,
    String text,
    Offset point, {
    required bool above,
  }) {
    final paragraph = TextPainterUtils.paragraph(
      text,
      _mainTextSize,
      maxWidth: _itemWidth,
    );
    final y = above ? point.dy - paragraph.height - 5 : point.dy + 5;
    canvas.drawParagraph(paragraph, Offset(point.dx - paragraph.width / 2, y));
  }

  double _topLineY(int temperature) {
    final range = _topMaxTemp - _topMinTemp;
    if (range == 0) return _topLineStartY + _lineHeight / 2;
    return _topLineStartY + (_topMaxTemp - temperature) / range * _lineHeight;
  }

  double _bottomLineY(int temperature) {
    final range = _bottomMaxTemp - _bottomMinTemp;
    if (range == 0) return _bottomLineStartY + _lineHeight / 2;
    return _bottomLineStartY +
        (_bottomMaxTemp - temperature) / range * _lineHeight;
  }

  @override
  bool shouldRepaint(covariant DailyForecastChartPainter oldDelegate) =>
      oldDelegate.imageRevision != imageRevision ||
      oldDelegate.data != data ||
      oldDelegate.height != height;
}
