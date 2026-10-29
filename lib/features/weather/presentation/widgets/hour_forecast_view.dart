/// 模块：小时预报（presentation/widgets）
/// 作用：横向温度曲线 + 天气图标 + 时间，对应设计图中的逐小时预报。
/// 依赖：Flutter、flutter_weather_bg + 本模块实体/样式/图片缓存。
library;

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_weather_bg/flutter_weather_bg.dart';

import '../../domain/entities/weather.dart';
import '../utils/text_painter_utils.dart';
import '../utils/time_formatter.dart';
import '../utils/weather_dimen.dart';
import '../utils/weather_image_cache.dart';
import '../utils/weather_style.dart';
import '../../../../app/widgets/blur_card.dart';

class HourForecastView extends StatelessWidget {
  const HourForecastView({super.key, required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final forecasts = weather.hourly?.forecasts ?? const <HourlyForecast>[];
    if (forecasts.isEmpty) return const SizedBox.shrink();
    final items = forecasts
        .map(
          (forecast) => HourlyChartItem(
            time: TimeFormatter.hourLabel(forecast.time),
            temperature: forecast.temperature,
            weatherType: WeatherStyle.typeOf(forecast.skycon),
            skycon: forecast.skycon,
          ),
        )
        .toList(growable: false);

    return BlurCard(
      child: SizedBox(
        height: WeatherDimen.hourChartHeight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: AnimatedBuilder(
            animation: WeatherImageCache.instance,
            builder: (context, _) => CustomPaint(
              painter: HourlyTemperatureChartPainter(
                items,
                imageRevision: WeatherImageCache.instance.revision,
              ),
              size: Size(items.length * 54.0, WeatherDimen.hourChartHeight),
            ),
          ),
        ),
      ),
    );
  }
}

class HourlyChartItem {
  const HourlyChartItem({
    required this.time,
    required this.temperature,
    required this.weatherType,
    required this.skycon,
  });

  final String time;
  final int temperature;
  final WeatherType weatherType;
  final String skycon;
}

class HourlyTemperatureChartPainter extends CustomPainter {
  HourlyTemperatureChartPainter(this.data, {required this.imageRevision});

  final List<HourlyChartItem> data;
  final int imageRevision;

  static const double _itemHeight = 80;
  static const double _circleRadius = 2;
  static const double _temperatureTextSize = 14;
  static const double _temperatureMarginBottom = 5;
  static const double _timeMarginTop = 5;
  static const double _iconHeight = 25;
  static const double _iconMargin = 10;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxTemperature = data.map((e) => e.temperature).reduce(max);
    final minTemperature = data.map((e) => e.temperature).reduce(min);
    final itemWidth = size.width / data.length;
    final span = maxTemperature - minTemperature;
    final gapHeight = span == 0 ? 1.0 : _itemHeight / span;
    final paint = Paint()..color = Colors.white;
    final linePath = Path();
    final points = <Offset>[];
    final startX = itemWidth / 2;
    final startY = _temperatureTextSize + _temperatureMarginBottom * 2;

    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final x = startX + i * itemWidth;
      final y =
          startY +
          _itemHeight -
          (item.temperature - minTemperature) * gapHeight;

      final temperatureParagraph = TextPainterUtils.paragraph(
        '${item.temperature}°',
        _temperatureTextSize,
        maxWidth: itemWidth,
      );
      canvas.drawParagraph(
        temperatureParagraph,
        Offset(
          x - temperatureParagraph.width / 2,
          y - temperatureParagraph.height - _temperatureMarginBottom,
        ),
      );

      final offset = Offset(x, y);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(offset, _circleRadius, paint);
      }
      points.add(offset);

      final timeParagraph = TextPainterUtils.paragraph(
        item.time,
        _temperatureTextSize,
        maxWidth: itemWidth,
      );
      canvas.drawParagraph(
        timeParagraph,
        Offset(
          x - timeParagraph.width / 2,
          startY + _itemHeight + _timeMarginTop + _iconHeight + _iconMargin * 2,
        ),
      );
    }

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, paint);
    _drawWeatherSegments(canvas, points, itemWidth, startY);
  }

  void _drawWeatherSegments(
    Canvas canvas,
    List<Offset> points,
    double itemWidth,
    double startY,
  ) {
    final paint = Paint()..style = PaintingStyle.fill;
    final path = Path();
    final segmentIndices = <int>{};
    var previousType = data.first.weatherType;
    segmentIndices.add(0);
    for (var i = 1; i < data.length; i++) {
      if (data[i].weatherType != previousType) {
        segmentIndices.add(i);
        previousType = data[i].weatherType;
      }
    }
    segmentIndices.add(data.length - 1);

    final indexes = segmentIndices.toList()..sort();
    final bottomY = startY + _itemHeight + _iconHeight + _iconMargin * 2;
    var alternate = true;

    for (var segment = 0; segment < indexes.length - 1; segment++) {
      final startIndex = indexes[segment];
      final endIndex = indexes[segment + 1];
      final segmentPoints = points.sublist(startIndex, endIndex + 1);
      if (segmentPoints.isEmpty) continue;
      path.reset();
      for (var i = 0; i < segmentPoints.length; i++) {
        final point = segmentPoints[i];
        if (i == 0) {
          path.moveTo(point.dx, bottomY);
        }
        path.lineTo(point.dx, point.dy);
        if (i == segmentPoints.length - 1) {
          path.lineTo(point.dx, bottomY);
          path.close();
        }
      }

      final middleX = (segmentPoints.first.dx + segmentPoints.last.dx) / 2;
      final middleY = startY + _itemHeight + _iconMargin;
      _drawIcon(canvas, data[endIndex].weatherType, middleX, middleY);

      alternate = !alternate;
      paint.shader = ui.Gradient.linear(
        Offset(0, startY),
        Offset(0, startY + _itemHeight + _iconHeight + _iconMargin * 3),
        <Color>[
          alternate ? const Color(0xFFFFFFFF) : const Color(0x88FFFFFF),
          const Color(0x00FFFFFF),
        ],
      );
      canvas.drawPath(path, paint);
    }
  }

  void _drawIcon(Canvas canvas, WeatherType type, double centerX, double topY) {
    final image = WeatherImageCache.instance.imageOf(type);
    if (image == null) return;
    final scale = _iconHeight / image.height;
    canvas.save();
    canvas.translate(centerX, topY + _iconHeight / 2);
    canvas.scale(scale);
    canvas.drawImage(
      image,
      Offset(-image.width / 2, -image.height / 2),
      Paint(),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HourlyTemperatureChartPainter oldDelegate) {
    // HourForecastView 每次 build 都会重新 map 出 items 列表，
    // 因此不能比较列表引用，否则每次 rebuild 都会触发一次实际绘制。
    if (oldDelegate.imageRevision != imageRevision) return true;
    final oldData = oldDelegate.data;
    if (oldData.length != data.length) return true;
    for (var i = 0; i < data.length; i++) {
      final oldItem = oldData[i];
      final newItem = data[i];
      if (oldItem.time != newItem.time ||
          oldItem.temperature != newItem.temperature ||
          oldItem.weatherType != newItem.weatherType ||
          oldItem.skycon != newItem.skycon) {
        return true;
      }
    }
    return false;
  }
}
