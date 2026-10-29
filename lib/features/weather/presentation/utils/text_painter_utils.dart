/// 模块：画布文字工具（presentation/utils）
/// 作用：在 CustomPainter 中居中绘制文字，并缓存已布局的 ui.Paragraph。
/// 性能说明：
///   - ui.ParagraphBuilder + layout 属于文字排版开销；
///   - 图表每次 rebuild 都会创建新的 Painter，因此在工具层做有上限的静态缓存；
///   - key 包含文本/字号/颜色/最大宽度，避免不同样式误用同一缓存。
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class TextPainterUtils {
  const TextPainterUtils._();

  static final Map<(String, double, int, double), ui.Paragraph> _cache =
      <(String, double, int, double), ui.Paragraph>{};
  static const int _maxEntries = 256;

  static ui.Paragraph paragraph(
    String text,
    double fontSize, {
    Color color = Colors.white,
    double maxWidth = 100,
  }) {
    final key = (text, fontSize, color.toARGB32(), maxWidth);
    final cached = _cache[key];
    if (cached != null) return cached;

    if (_cache.length >= _maxEntries) {
      _cache.clear();
    }

    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: fontSize),
    );
    builder.pushStyle(ui.TextStyle(color: color));
    builder.addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));
    _cache[key] = paragraph;
    return paragraph;
  }
}
