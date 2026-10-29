/// 模块：实时天气主视觉（presentation/widgets）
/// 作用：展示大号温度、天气图标、天气描述与预报摘要；点击摘要有降水详情。
/// 依赖：Flutter + 本模块实体/样式。
library;

import 'package:flutter/material.dart';

import '../../domain/entities/weather.dart';
import '../utils/weather_style.dart';
import '../../../../app/widgets/blur_card.dart';
import 'rain_detail_sheet.dart';

class RealtimeView extends StatelessWidget {
  const RealtimeView({super.key, required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final realtime = weather.realtime;
    final skycon = realtime?.skycon;
    final weatherType = WeatherStyle.typeOf(skycon);
    final temperature = realtime?.temperature?.toString() ?? '--';
    final keypoint = weather.forecastKeypoint ?? '';

    return SizedBox(
      height: 264,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 10),
              Text(
                temperature,
                style: const TextStyle(
                  fontSize: 132,
                  height: 1,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  '°',
                  style: TextStyle(fontSize: 46, color: Colors.white),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 8),
                child: Image.asset(
                  WeatherStyle.iconFor(weatherType),
                  width: 58,
                  height: 58,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              WeatherStyle.description(skycon),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (keypoint.isNotEmpty)
            InkWell(
              onTap: () => _showRainDetail(context),
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        keypoint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }

  void _showRainDetail(BuildContext context) {
    final precipitation = weather.minutely?.precipitation2h ?? const <double>[];
    final colors = WeatherStyle.colors(
      WeatherStyle.typeOf(weather.realtime?.skycon),
    );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => BlurCard(
        color: colors.first.withValues(alpha: 0.72),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.32,
          child: RainDetailSheet(
            precipitation: precipitation,
            title: weather.forecastKeypoint ?? '未来两小时降水',
          ),
        ),
      ),
    );
  }
}
