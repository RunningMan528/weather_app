/// 模块：城市管理天气卡片（city/presentation/widgets）
/// 作用：展示 CityWeatherSummary；不依赖天气 feature 的实体、用例或 UI。
/// 依赖：Flutter + 本模块领域实体/视觉映射。
library;

import 'package:flutter/material.dart';

import '../../domain/entities/city_weather_summary.dart';
import '../utils/city_weather_visual.dart';

class CityWeatherCard extends StatelessWidget {
  const CityWeatherCard({
    super.key,
    required this.summary,
    required this.isSelected,
    required this.onTap,
  });

  final CityWeatherSummary summary;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final city = summary.city;
    final condition = summary.condition;
    final colors = CityWeatherVisual.colors(condition);
    final description = CityWeatherVisual.label(condition);
    final currentTemperature = summary.temperature == null
        ? ''
        : '${summary.temperature}°';
    final todayTemperature =
        summary.maxTemperature == null || summary.minTemperature == null
        ? ''
        : '${summary.maxTemperature}°/${summary.minTemperature}°';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (description.isNotEmpty && todayTemperature.isNotEmpty)
                        const SizedBox(width: 6),
                      if (todayTemperature.isNotEmpty)
                        Text(
                          todayTemperature,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          city.displayedName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (city.isLocated) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Image.asset(
              CityWeatherVisual.icon(condition),
              width: 34,
              height: 34,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(width: 6),
            Text(
              currentTemperature,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
