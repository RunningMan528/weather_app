/// 模块：实时详情（presentation/widgets）
/// 作用：日出日落 + 体感/湿度/气压/风速/PM25/紫外线指标。
/// 依赖：Flutter + 本模块实体 + blur_card/sun_rise_set_view。
library;

import 'package:flutter/material.dart';

import '../../domain/entities/weather.dart';
import '../utils/weather_style.dart';
import '../../../../app/widgets/blur_card.dart';
import 'sun_rise_set_view.dart';

class RealtimeDetailView extends StatelessWidget {
  const RealtimeDetailView({super.key, required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final realtime = weather.realtime;
    final astro = weather.daily?.astros.isNotEmpty == true
        ? weather.daily!.astros.first
        : null;
    final skycon = realtime?.skycon;

    return BlurCard(
      color: _cardColor(skycon),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            SunRiseSetView(astro: astro),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _DetailGrid(
                items: <_DetailItemData>[
                  _DetailItemData(
                    label: '体感',
                    value: realtime?.apparentTemperature == null
                        ? '--'
                        : '${realtime!.apparentTemperature!.toInt()}°',
                  ),
                  _DetailItemData(
                    label: '湿度',
                    value: realtime?.humidity == null
                        ? '--'
                        : '${(realtime!.humidity! * 100).toInt()}%',
                  ),
                  _DetailItemData(
                    label: '气压',
                    value: realtime?.pressure == null
                        ? '--'
                        : '${realtime!.pressure!.toStringAsFixed(1)}hPa',
                  ),
                  _DetailItemData(
                    label: '风速',
                    value: realtime?.wind?.speed == null
                        ? '--'
                        : '${realtime!.wind!.speed}km/h',
                  ),
                  _DetailItemData(
                    label: 'PM25',
                    value: realtime?.airQuality?.pm25?.toString() ?? '--',
                  ),
                  _DetailItemData(
                    label: '紫外线',
                    value: realtime?.ultravioletIndex?.toString() ?? '--',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _cardColor(String? skycon) {
    final colors = WeatherStyle.colors(WeatherStyle.typeOf(skycon));
    return colors.first.withValues(alpha: 0.22);
  }
}

class _DetailItemData {
  const _DetailItemData({required this.label, required this.value});

  final String label;
  final String value;
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.items});

  final List<_DetailItemData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 18.0;
        final itemWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: 22,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
