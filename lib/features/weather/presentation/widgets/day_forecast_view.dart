/// 模块：今明两天预报卡片（presentation/widgets）
/// 作用：对应设计图底部的"今天/明天"两张卡片，点击可查看多天趋势。
/// 依赖：Flutter + 本模块实体/样式。
library;

import 'package:flutter/material.dart';

import '../../domain/entities/weather.dart';
import '../utils/time_formatter.dart';
import '../utils/weather_dimen.dart';
import '../utils/weather_style.dart';
import '../../../../app/widgets/blur_card.dart';
import 'multi_day_forecast_view.dart';

class DayForecastView extends StatelessWidget {
  const DayForecastView({super.key, required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final forecasts = weather.daily?.forecasts ?? const <DailyForecast>[];
    if (forecasts.isEmpty) return const SizedBox.shrink();
    final visible = forecasts.take(2).toList(growable: false);
    return Row(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(width: WeatherDimen.cardInnerGap),
          Expanded(
            child: SizedBox(
              height: WeatherDimen.singleDayForecastHeight,
              child: _DayCard(
                forecast: visible[i],
                onTap: () => _showDetail(context),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showDetail(BuildContext context) {
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
        child: MultiDayForecastView(
          weather: weather,
          height:
              MediaQuery.sizeOf(sheetContext).height *
              WeatherDimen.dayDetailHeightRatio,
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.forecast, required this.onTap});

  final DailyForecast forecast;
  final VoidCallback onTap;

  String get _description {
    if (forecast.daySkycon.isEmpty && forecast.nightSkycon.isEmpty) {
      return WeatherStyle.description(forecast.fullSkycon);
    }
    final day = WeatherStyle.description(forecast.daySkycon);
    final night = WeatherStyle.description(forecast.nightSkycon);
    return day == night ? day : '$day转$night';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BlurCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      TimeFormatter.weatherDayLabel(forecast.date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _description,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${forecast.maxTemperature}°/${forecast.minTemperature}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 62,
                    child: Text(
                      WeatherStyle.aqiDescription(forecast.aqiMax),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
