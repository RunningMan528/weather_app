/// 模块：分钟级降水详情（presentation/widgets）
/// 作用：用折线图展示未来两小时降水强度。
/// 依赖：Flutter + text_painter_utils。
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../utils/text_painter_utils.dart';

class RainDetailSheet extends StatelessWidget {
  const RainDetailSheet({
    super.key,
    required this.precipitation,
    required this.title,
  });

  final List<double> precipitation;
  final String title;

  @override
  Widget build(BuildContext context) {
    final hasRain = precipitation.any((value) => value > 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: hasRain
              ? CustomPaint(painter: RainDetailPainter(precipitation))
              : const Center(
                  child: Text(
                    '未来两小时暂无降水',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
        ),
      ],
    );
  }
}

class RainDetailPainter extends CustomPainter {
  RainDetailPainter(this.data);

  final List<double> data;

  static const double _marginLeft = 30;
  static const double _marginRight = 30;
  static const double _marginBottom = 60;
  static const double _timeMarginTop = 10;
  static const double _textSize = 12;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawLine(canvas, size);
  }

  void _drawLine(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint();
    final path = Path();
    final width = size.width - _marginLeft - _marginRight;
    final height = size.height - _marginBottom;
    final itemWidth = width / 120;
    final itemHeight = height / 100;
    for (var i = 0; i < data.length; i++) {
      final x = _marginLeft + i * itemWidth;
      final y = height - data[i] * 100 * itemHeight;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white;
    canvas.drawPath(path, paint);

    path
      ..lineTo(_marginLeft + width, height)
      ..lineTo(_marginLeft, height)
      ..close();
    paint
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, height),
        const <Color>[Color(0xFFFFFFFF), Color(0x00FFFFFF)],
      );
    canvas.drawPath(path, paint);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.4);
    final itemHeight = (size.height - _marginBottom) / 3;
    final width = size.width - _marginLeft - _marginRight;
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(_marginLeft, itemHeight * i),
        Offset(_marginLeft + width, itemHeight * i),
        paint,
      );
    }

    final hourY = size.height - _marginBottom + _timeMarginTop;
    _drawText(canvas, '现在', Offset(_marginLeft, hourY));
    _drawText(canvas, '1小时后', Offset(_marginLeft + width / 2, hourY));
    _drawText(canvas, '2小时后', Offset(_marginLeft + width, hourY));
    _drawText(canvas, '大', const Offset(15, 0));
    _drawText(canvas, '中', Offset(15, itemHeight));
    _drawText(canvas, '小', Offset(15, itemHeight * 2));
  }

  void _drawText(Canvas canvas, String text, Offset offset) {
    final paragraph = TextPainterUtils.paragraph(text, _textSize, maxWidth: 80);
    canvas.drawParagraph(
      paragraph,
      Offset(offset.dx - paragraph.width / 2, offset.dy),
    );
  }

  @override
  bool shouldRepaint(covariant RainDetailPainter oldDelegate) =>
      oldDelegate.data != data;
}
