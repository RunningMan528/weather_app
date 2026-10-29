/// 模块：通用左滑删除卡片（app/widgets）
/// 作用：向左滑动卡片露出红色"删除"按钮；点击按钮直接删除，不再弹窗。
/// 依赖：Flutter（无第三方 slidable 依赖，不依赖任何 feature）。
library;

import 'package:flutter/material.dart';

class SwipeDeleteCard extends StatefulWidget {
  const SwipeDeleteCard({
    super.key,
    required this.child,
    required this.onDelete,
  });

  final Widget child;
  final VoidCallback onDelete;

  @override
  State<SwipeDeleteCard> createState() => _SwipeDeleteCardState();
}

class _SwipeDeleteCardState extends State<SwipeDeleteCard>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 88;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  Animation<double>? _animation;
  double _offset = 0;

  @override
  void dispose() {
    _animation?.removeListener(_onAnimationTick);
    _controller.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    final animation = _animation;
    if (!mounted || animation == null) return;
    setState(() => _offset = animation.value);
  }

  void _animateTo(double target) {
    _animation?.removeListener(_onAnimationTick);
    final animation = Tween<double>(
      begin: _offset,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _animation = animation;
    animation.addListener(_onAnimationTick);
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      animation.removeListener(_onAnimationTick);
      _animation = null;
      setState(() => _offset = target);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_animation != null) return;
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(-_actionWidth, 0.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldOpen = _offset < -_actionWidth / 2 || velocity < -350;
    _animateTo(shouldOpen ? -_actionWidth : 0);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: _actionWidth,
                child: Material(
                  color: const Color(0xFFE53935),
                  child: InkWell(
                    onTap: widget.onDelete,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '删除',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_offset, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onTap: _offset < -1 ? () => _animateTo(0) : null,
              child: IgnorePointer(ignoring: _offset < -1, child: widget.child),
            ),
          ),
        ],
      ),
    );
  }
}
