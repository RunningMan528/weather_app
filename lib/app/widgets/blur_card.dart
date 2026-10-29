/// 模块：通用毛玻璃卡片（app/widgets）
/// 作用：跨 feature 复用的半透明模糊卡片容器。
/// 依赖：Flutter（不依赖任何 feature）。
library;

import 'dart:ui';

import 'package:flutter/material.dart';

class BlurCard extends StatelessWidget {
  const BlurCard({
    super.key,
    this.child,
    this.color = Colors.black12,
    this.borderRadius,
    this.sigma = 5,
    this.padding,
  });

  final Widget? child;
  final Color color;
  final BorderRadius? borderRadius;
  final double sigma;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? const BorderRadius.all(Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(color: color, padding: padding, child: child),
      ),
    );
  }
}
