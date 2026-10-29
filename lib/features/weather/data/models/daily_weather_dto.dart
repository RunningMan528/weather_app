/// 模块：多天预报 DTO（data/models）
/// 作用：解析彩云 daily 字段，并把平行数组按索引合并成 DailyForecast 列表。
/// 依赖：纯 Dart + 本模块领域实体 + json_helpers。
library;

import '../../domain/entities/weather.dart';
import '../../../../core/utils/json_helpers.dart';

class DailyWeatherDto {
  const DailyWeatherDto({
    this.astro = const <AstroDto>[],
    this.temperature = const <DailyTemperatureDto>[],
    this.wind = const <DailyWindDto>[],
    this.aqi = const <DailyAqiDto>[],
    this.skycon = const <DailySkyconDto>[],
    this.daySkycon = const <DailySkyconDto>[],
    this.nightSkycon = const <DailySkyconDto>[],
    this.lifeIndex,
  });

  factory DailyWeatherDto.fromJson(Map<String, dynamic> json) {
    final airQuality = asMap(json['air_quality']);
    final lifeIndex = asMapOrNull(json['life_index']);
    return DailyWeatherDto(
      astro: asMapList(json['astro'])
          .map(AstroDto.fromJson)
          .toList(growable: false),
      temperature: asMapList(json['temperature'])
          .map(DailyTemperatureDto.fromJson)
          .toList(growable: false),
      wind: asMapList(json['wind'])
          .map(DailyWindDto.fromJson)
          .toList(growable: false),
      aqi: asMapList(airQuality['aqi'])
          .map(DailyAqiDto.fromJson)
          .toList(growable: false),
      skycon: asMapList(json['skycon'])
          .map(DailySkyconDto.fromJson)
          .toList(growable: false),
      daySkycon: asMapList(json['skycon_08h_20h'])
          .map(DailySkyconDto.fromJson)
          .toList(growable: false),
      nightSkycon: asMapList(json['skycon_20h_32h'])
          .map(DailySkyconDto.fromJson)
          .toList(growable: false),
      lifeIndex: lifeIndex == null
          ? null
          : DailyLifeIndexDto.fromJson(lifeIndex),
    );
  }

  final List<AstroDto> astro;
  final List<DailyTemperatureDto> temperature;
  final List<DailyWindDto> wind;
  final List<DailyAqiDto> aqi;
  final List<DailySkyconDto> skycon;
  final List<DailySkyconDto> daySkycon;
  final List<DailySkyconDto> nightSkycon;
  final DailyLifeIndexDto? lifeIndex;

  DailyWeather toEntity() {
    final forecasts = <DailyForecast>[];
    for (var i = 0; i < temperature.length; i++) {
      final temp = temperature[i];
      forecasts.add(
        DailyForecast(
          date: temp.date,
          maxTemperature: temp.max ?? 0,
          minTemperature: temp.min ?? 0,
          fullSkycon: i < skycon.length ? (skycon[i].value ?? '') : '',
          daySkycon: i < daySkycon.length ? (daySkycon[i].value ?? '') : '',
          nightSkycon: i < nightSkycon.length
              ? (nightSkycon[i].value ?? '')
              : '',
          windSpeed: i < wind.length ? (wind[i].speed ?? 0) : 0,
          windDirection: i < wind.length ? (wind[i].direction ?? 0) : 0,
          aqiMax: i < aqi.length ? aqi[i].maxChn : null,
        ),
      );
    }
    return DailyWeather(
      forecasts: forecasts,
      astros: astro.map((e) => e.toEntity()).toList(growable: false),
      lifeIndex: lifeIndex?.toEntity(),
    );
  }
}

class AstroDto {
  const AstroDto({this.date, this.sunrise, this.sunset});

  factory AstroDto.fromJson(Map<String, dynamic> json) => AstroDto(
    date: asString(json['date']),
    sunrise: asString(asMap(json['sunrise'])['time']),
    sunset: asString(asMap(json['sunset'])['time']),
  );

  final String? date;
  final String? sunrise;
  final String? sunset;

  Astro toEntity() => Astro(date: date, sunrise: sunrise, sunset: sunset);
}

class DailyTemperatureDto {
  const DailyTemperatureDto({this.date, this.max, this.min});

  factory DailyTemperatureDto.fromJson(Map<String, dynamic> json) =>
      DailyTemperatureDto(
        date: asString(json['date']),
        max: asInt(json['max']),
        min: asInt(json['min']),
      );

  final String? date;
  final int? max;
  final int? min;
}

class DailyWindDto {
  const DailyWindDto({this.speed, this.direction});

  factory DailyWindDto.fromJson(Map<String, dynamic> json) {
    final avg = asMap(json['avg']);
    return DailyWindDto(
      speed: asDouble(avg['speed']),
      direction: asDouble(avg['direction']),
    );
  }

  final double? speed;
  final double? direction;
}

class DailyAqiDto {
  const DailyAqiDto({this.date, this.maxChn});

  factory DailyAqiDto.fromJson(Map<String, dynamic> json) => DailyAqiDto(
    date: asString(json['date']),
    maxChn: asInt(asMap(json['max'])['chn']),
  );

  final String? date;
  final int? maxChn;
}

class DailySkyconDto {
  const DailySkyconDto({this.date, this.value});

  factory DailySkyconDto.fromJson(Map<String, dynamic> json) => DailySkyconDto(
    date: asString(json['date']),
    value: asString(json['value']),
  );

  final String? date;
  final String? value;
}

class DailyLifeIndexDto {
  const DailyLifeIndexDto({
    this.ultraviolet = const <LifeIndexEntryDto>[],
    this.carWashing = const <LifeIndexEntryDto>[],
    this.dressing = const <LifeIndexEntryDto>[],
    this.comfort = const <LifeIndexEntryDto>[],
    this.coldRisk = const <LifeIndexEntryDto>[],
  });

  factory DailyLifeIndexDto.fromJson(Map<String, dynamic> json) =>
      DailyLifeIndexDto(
        ultraviolet: _entries(json['ultraviolet']),
        carWashing: _entries(json['carWashing']),
        dressing: _entries(json['dressing']),
        comfort: _entries(json['comfort']),
        coldRisk: _entries(json['coldRisk']),
      );

  final List<LifeIndexEntryDto> ultraviolet;
  final List<LifeIndexEntryDto> carWashing;
  final List<LifeIndexEntryDto> dressing;
  final List<LifeIndexEntryDto> comfort;
  final List<LifeIndexEntryDto> coldRisk;

  static List<LifeIndexEntryDto> _entries(dynamic value) =>
      asMapList(value).map(LifeIndexEntryDto.fromJson).toList(growable: false);

  DailyLifeIndex toEntity() => DailyLifeIndex(
    ultraviolet: ultraviolet.map((e) => e.toEntity()).toList(growable: false),
    carWashing: carWashing.map((e) => e.toEntity()).toList(growable: false),
    dressing: dressing.map((e) => e.toEntity()).toList(growable: false),
    comfort: comfort.map((e) => e.toEntity()).toList(growable: false),
    coldRisk: coldRisk.map((e) => e.toEntity()).toList(growable: false),
  );
}

class LifeIndexEntryDto {
  const LifeIndexEntryDto({this.date, this.index, this.desc});

  factory LifeIndexEntryDto.fromJson(Map<String, dynamic> json) =>
      LifeIndexEntryDto(
        date: asString(json['date']),
        index: asString(json['index']),
        desc: asString(json['desc']),
      );

  final String? date;
  final String? index;
  final String? desc;

  LifeIndexEntry toEntity() =>
      LifeIndexEntry(date: date, index: index, desc: desc);
}
