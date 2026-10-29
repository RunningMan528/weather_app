/// 模块：AQI 与湿度环形图（presentation/widgets）
/// 作用：对应设计图中两张并排的圆环指标卡片。
/// 依赖：Flutter + 本模块实体/样式。
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/entities/weather.dart';
import '../utils/text_painter_utils.dart';
import '../utils/weather_dimen.dart';
import '../../../../app/widgets/blur_card.dart';

class AqiChartView extends StatelessWidget {
  const AqiChartView({super.key, required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final cardWidth =
        (MediaQuery.sizeOf(context).width -
            WeatherDimen.pageHorizontal * 2 -
            WeatherDimen.cardInnerGap) /
        2;
    final aqi = weather.realtime?.airQuality?.aqiChn;
    final humidity = weather.realtime?.humidity ?? 0;
    final humidityPercent = (humidity * 100).toInt();

    return Row(
      children: [
        BlurCard(
          child: SizedBox(
            width: cardWidth,
            height: WeatherDimen.aqiChartHeight,
            child: CustomPaint(
              painter: RingChartPainter(
                value: aqi?.toString() ?? '--',
                label: weather.realtime?.airQuality?.descriptionChn ?? '',
                ratio: ((aqi ?? 0) / 500).clamp(0.0, 1.0),
              ),
            ),
          ),
        ),
        const SizedBox(width: WeatherDimen.cardInnerGap),
        BlurCard(
          child: SizedBox(
            width: cardWidth,
            height: WeatherDimen.aqiChartHeight,
            child: CustomPaint(
              painter: RingChartPainter(
                value: '$humidityPercent%',
                label: '湿度',
                ratio: humidity.clamp(0.0, 1.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RingChartPainter extends CustomPainter {
  RingChartPainter({
    required this.value,
    required this.label,
    required this.ratio,
  });

  final String value;
  final String label;
  final double ratio;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2 - 10;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final backgroundPath = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: radius),
        pi * 0.7,
        pi * 1.6,
      );
    paint.color = Colors.white38;
    canvas.drawPath(backgroundPath, paint);

    final progressPath = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: radius),
        pi * 0.7,
        pi * 1.6 * ratio,
      );
    paint.color = Colors.white;
    canvas.drawPath(progressPath, paint);

    final valueParagraph = TextPainterUtils.paragraph(
      value,
      30,
      maxWidth: size.width,
    );
    canvas.drawParagraph(
      valueParagraph,
      Offset(
        center.dx - valueParagraph.width / 2,
        center.dy - valueParagraph.height / 2,
      ),
    );

    if (label.isNotEmpty) {
      final labelParagraph = TextPainterUtils.paragraph(
        label,
        14,
        maxWidth: size.width,
      );
      canvas.drawParagraph(
        labelParagraph,
        Offset(
          center.dx - labelParagraph.width / 2,
          center.dy + valueParagraph.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RingChartPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.label != label ||
      oldDelegate.ratio != ratio;
}
