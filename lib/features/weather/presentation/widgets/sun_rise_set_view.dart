/// 模块：日出日落弧线（presentation/widgets）
/// 作用：绘制从日出到日落的虚线弧，并按当前时间高亮已走过的部分。
/// 依赖：Flutter + path_drawing + text_painter_utils。
library;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../domain/entities/weather.dart';
import '../utils/text_painter_utils.dart';
import '../utils/weather_dimen.dart';

class SunRiseSetView extends StatelessWidget {
  const SunRiseSetView({super.key, required this.astro});

  final Astro? astro;

  @override
  Widget build(BuildContext context) {
    final sunrise = astro?.sunrise;
    final sunset = astro?.sunset;
    if (sunrise == null ||
        sunrise.isEmpty ||
        sunset == null ||
        sunset.isEmpty) {
      return const SizedBox.shrink();
    }
    final width =
        MediaQuery.sizeOf(context).width - WeatherDimen.pageHorizontal * 2;
    return Column(
      children: [
        SizedBox(
          height: 140,
          width: width,
          child: CustomPaint(
            painter: SunRiseSetPainter(sunrise: sunrise, sunset: sunset),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('日出 $sunrise', style: const TextStyle(color: Colors.white)),
              Text('日落 $sunset', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class SunRiseSetPainter extends CustomPainter {
  SunRiseSetPainter({required this.sunrise, required this.sunset})
    : _ratio = _computeRatio(sunrise, sunset);

  final String sunrise;
  final String sunset;
  final double _ratio;

  static double _computeRatio(String sunrise, String sunset) {
    final sunriseMinute = _minuteOfDay(sunrise);
    final sunsetMinute = _minuteOfDay(sunset);
    final now = DateTime.now();
    final nowMinute = now.hour * 60 + now.minute;
    final span = sunsetMinute - sunriseMinute;
    if (span <= 0) return 0;
    return ((nowMinute - sunriseMinute) / span).clamp(0.0, 1.0);
  }

  static int _minuteOfDay(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const marginLeftRight = 20.0;
    const marginBottom = 20.0;
    const marginTop = -40.0;

    final startX = marginLeftRight;
    final startY = size.height - marginBottom;
    final endX = size.width - marginLeftRight;
    final path = Path()
      ..moveTo(startX, startY)
      ..quadraticBezierTo(size.width / 2, marginTop, endX, startY);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(
      dashPath(path, dashArray: CircularIntervalList<double>(<double>[10, 5])),
      paint,
    );

    final metric = path.computeMetrics().first;
    final tangent = metric.getTangentForOffset(metric.length * _ratio);
    final sunOffset = tangent?.position ?? Offset.zero;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, sunOffset.dx, size.height));
    canvas.drawPath(path, paint);
    canvas.restore();

    paint
      ..style = PaintingStyle.fill
      ..color = Colors.yellow;
    canvas.drawCircle(sunOffset, 6, paint);

    final nowParagraph = TextPainterUtils.paragraph(_nowLabel(), 14);
    canvas.drawParagraph(
      nowParagraph,
      Offset(sunOffset.dx - nowParagraph.width / 2, sunOffset.dy + 10),
    );
  }

  String _nowLabel() {
    final now = DateTime.now();
    final minute = now.minute.toString().padLeft(2, '0');
    return '${now.hour}:$minute';
  }

  @override
  bool shouldRepaint(covariant SunRiseSetPainter oldDelegate) =>
      oldDelegate.sunrise != sunrise ||
      oldDelegate.sunset != sunset ||
      oldDelegate._ratio != _ratio;
}
