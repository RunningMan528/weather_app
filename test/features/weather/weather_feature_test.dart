/// 模块：天气功能测试
/// 覆盖：DTO 解析、小时/多天平行数组合并、生活指数、时间格式化。
/// 运行：flutter test test/features/weather/weather_feature_test.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/data/models/weather_dto.dart';
import 'package:weather_app/features/weather/presentation/utils/time_formatter.dart';

void main() {
  group('WeatherDto', () {
    test('把彩云天气 JSON 转换为领域实体', () {
      final weather = WeatherDto.fromJson(_sampleJson()).toEntity();

      expect(weather.realtime?.temperature, 23);
      expect(weather.realtime?.humidity, 0.76);
      expect(weather.realtime?.skycon, 'CLEAR_DAY');
      expect(weather.realtime?.apparentTemperature, 24.2);
      expect(weather.realtime?.wind?.speed, 21.6);
      expect(weather.realtime?.airQuality?.pm25, 10);
      expect(weather.realtime?.airQuality?.aqiChn, 55);
      expect(weather.realtime?.airQuality?.descriptionChn, '良');
      expect(weather.realtime?.ultravioletIndex, 3);
      expect(weather.minutely?.precipitation2h, <double>[0, 0.1, 0.2]);
      expect(weather.forecastKeypoint, '最近的降雨带在东北64公里外呢');
    });

    test('把小时/多天平行数组按索引合并', () {
      final weather = WeatherDto.fromJson(_sampleJson()).toEntity();

      final hour = weather.hourly?.forecasts.single;
      expect(hour?.time, '2026-10-28T18:00+08:00');
      expect(hour?.temperature, 23);
      expect(hour?.skycon, 'CLEAR_DAY');
      expect(hour?.windSpeed, 10.5);
      expect(hour?.aqi, 55);

      final day = weather.daily?.forecasts.single;
      expect(day?.maxTemperature, 26);
      expect(day?.minTemperature, 17);
      expect(day?.daySkycon, 'PARTLY_CLOUDY_DAY');
      expect(day?.nightSkycon, 'CLOUDY');
      expect(day?.windSpeed, 12.3);
      expect(day?.aqiMax, 59);
      expect(weather.daily?.astros.single.sunrise, '06:15');
      expect(weather.daily?.astros.single.sunset, '18:18');
      expect(weather.daily?.lifeIndex?.carWashing.single.desc, '较适宜');
    });
  });

  group('TimeFormatter', () {
    test('兼容日期与带时区时间字符串', () {
      expect(TimeFormatter.tryParse('2026-10-28')?.day, 28);
      expect(TimeFormatter.tryParse('2026-10-28T18:05+08:00')?.hour, 18);
      expect(TimeFormatter.hourLabel('2026-10-28T18:05+08:00'), '18:05');
      expect(TimeFormatter.dayMonthLabel('2026-10-28'), '10月28日');
    });

    test('非法输入返回空字符串', () {
      expect(TimeFormatter.hourLabel(null), '');
      expect(TimeFormatter.dayMonthLabel(''), '');
      expect(TimeFormatter.tryParse('not-a-date'), isNull);
    });
  });
}

Map<String, dynamic> _sampleJson() => <String, dynamic>{
  'status': 'ok',
  'location': <double>[116.4, 39.9],
  'result': <String, dynamic>{
    'forecast_keypoint': '最近的降雨带在东北64公里外呢',
    'realtime': <String, dynamic>{
      'temperature': 23,
      'humidity': 0.76,
      'skycon': 'CLEAR_DAY',
      'apparent_temperature': 24.2,
      'pressure': 100568.05,
      'wind': <String, dynamic>{'speed': 21.6, 'direction': 180},
      'air_quality': <String, dynamic>{
        'pm25': 10,
        'aqi': <String, dynamic>{'chn': 55, 'usa': 40},
        'description': <String, dynamic>{'chn': '良', 'usa': 'Moderate'},
      },
      'life_index': <String, dynamic>{
        'ultraviolet': <String, dynamic>{'index': 3, 'desc': '中等'},
      },
    },
    'minutely': <String, dynamic>{
      'precipitation_2h': <double>[0, 0.1, 0.2],
    },
    'hourly': <String, dynamic>{
      'temperature': <Map<String, dynamic>>[
        <String, dynamic>{'datetime': '2026-10-28T18:00+08:00', 'value': 23},
      ],
      'skycon': <Map<String, dynamic>>[
        <String, dynamic>{
          'datetime': '2026-10-28T18:00+08:00',
          'value': 'CLEAR_DAY',
        },
      ],
      'wind': <Map<String, dynamic>>[
        <String, dynamic>{
          'datetime': '2026-10-28T18:00+08:00',
          'speed': 10.5,
          'direction': 180,
        },
      ],
      'air_quality': <String, dynamic>{
        'aqi': <Map<String, dynamic>>[
          <String, dynamic>{
            'datetime': '2026-10-28T18:00+08:00',
            'value': <String, dynamic>{'chn': 55},
          },
        ],
      },
    },
    'daily': <String, dynamic>{
      'astro': <Map<String, dynamic>>[
        <String, dynamic>{
          'date': '2026-10-28',
          'sunrise': <String, dynamic>{'time': '06:15'},
          'sunset': <String, dynamic>{'time': '18:18'},
        },
      ],
      'temperature': <Map<String, dynamic>>[
        <String, dynamic>{'date': '2026-10-28', 'max': 26, 'min': 17},
      ],
      'wind': <Map<String, dynamic>>[
        <String, dynamic>{
          'date': '2026-10-28',
          'avg': <String, dynamic>{'speed': 12.3, 'direction': 90},
        },
      ],
      'air_quality': <String, dynamic>{
        'aqi': <Map<String, dynamic>>[
          <String, dynamic>{
            'date': '2026-10-28',
            'max': <String, dynamic>{'chn': 59},
          },
        ],
      },
      'skycon': <Map<String, dynamic>>[
        <String, dynamic>{'date': '2026-10-28', 'value': 'PARTLY_CLOUDY_DAY'},
      ],
      'skycon_08h_20h': <Map<String, dynamic>>[
        <String, dynamic>{'date': '2026-10-28', 'value': 'PARTLY_CLOUDY_DAY'},
      ],
      'skycon_20h_32h': <Map<String, dynamic>>[
        <String, dynamic>{'date': '2026-10-28', 'value': 'CLOUDY'},
      ],
      'life_index': <String, dynamic>{
        'ultraviolet': <Map<String, dynamic>>[
          <String, dynamic>{'date': '2026-10-28', 'index': '3', 'desc': '中等'},
        ],
        'carWashing': <Map<String, dynamic>>[
          <String, dynamic>{'date': '2026-10-28', 'index': '1', 'desc': '较适宜'},
        ],
        'dressing': <Map<String, dynamic>>[
          <String, dynamic>{'date': '2026-10-28', 'index': '2', 'desc': '温暖'},
        ],
        'comfort': <Map<String, dynamic>>[
          <String, dynamic>{'date': '2026-10-28', 'index': '1', 'desc': '舒适'},
        ],
        'coldRisk': <Map<String, dynamic>>[
          <String, dynamic>{'date': '2026-10-28', 'index': '1', 'desc': '少发'},
        ],
      },
    },
  },
};
