/// 模块：天气页状态视图（presentation/widgets）
/// 作用：首屏 loading 与错误重试的统一视觉。
/// 依赖：Flutter + blur_card。
library;

import 'package:flutter/material.dart';

import '../../../../app/widgets/blur_card.dart';

class WeatherLoadingView extends StatelessWidget {
  const WeatherLoadingView({super.key, this.message = '正在获取天气…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _WeatherStatusScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          Text(message, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class WeatherErrorView extends StatelessWidget {
  const WeatherErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _WeatherStatusScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          if (onRetry != null)
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
        ],
      ),
    );
  }
}

class _WeatherStatusScaffold extends StatelessWidget {
  const _WeatherStatusScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BlurCard(
        color: Colors.black.withValues(alpha: 0.20),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: child,
      ),
    );
  }
}
