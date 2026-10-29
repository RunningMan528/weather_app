/// 模块：天气 DTO（data/models）
/// 作用：与彩云天气 JSON 一一对应，负责 fromJson 与 DTO → 领域实体转换。
/// 依赖：纯 Dart + 本模块领域实体 + json_helpers。
/// 说明：保留 [raw] 以便仓库把原始响应写入本地缓存，领域实体本身不含 JSON。
library;

import '../../domain/entities/weather.dart';
import 'daily_weather_dto.dart';
import '../../../../core/utils/json_helpers.dart';

class WeatherDto {
  const WeatherDto({
    required this.raw,
    this.realtime,
    this.minutely,
    this.hourly,
    this.daily,
    this.forecastKeypoint,
    this.location = const <double>[],
  });

  factory WeatherDto.fromJson(Map<String, dynamic> json) {
    final status = asString(json['status']);
    if (status != null && status != 'ok') {
      throw FormatException('天气接口返回失败：$status');
    }
    final result = asMap(json['result']);
    if (result.isEmpty) {
      throw const FormatException('天气接口返回缺少 result');
    }
    final realtime = asMapOrNull(result['realtime']);
    final minutely = asMapOrNull(result['minutely']);
    final hourly = asMapOrNull(result['hourly']);
    final daily = asMapOrNull(result['daily']);
    return WeatherDto(
      raw: json,
      realtime: realtime == null ? null : RealtimeDto.fromJson(realtime),
      minutely: minutely == null ? null : MinutelyDto.fromJson(minutely),
      hourly: hourly == null ? null : HourlyDto.fromJson(hourly),
      daily: daily == null ? null : DailyWeatherDto.fromJson(daily),
      forecastKeypoint: asString(result['forecast_keypoint']),
      location: asDoubleList(json['location']),
    );
  }

  /// 原始 JSON：仓库用它做本地缓存，避免额外实现 toJson。
  final Map<String, dynamic> raw;
  final RealtimeDto? realtime;
  final MinutelyDto? minutely;
  final HourlyDto? hourly;
  final DailyWeatherDto? daily;
  final String? forecastKeypoint;
  final List<double> location;

  Weather toEntity() => Weather(
    realtime: realtime?.toEntity(),
    minutely: minutely?.toEntity(),
    hourly: hourly?.toEntity(),
    daily: daily?.toEntity(),
    forecastKeypoint: forecastKeypoint,
    location: location,
  );
}

class RealtimeDto {
  const RealtimeDto({
    this.temperature,
    this.humidity,
    this.skycon,
    this.pressure,
    this.apparentTemperature,
    this.wind,
    this.airQuality,
    this.ultravioletIndex,
  });

  factory RealtimeDto.fromJson(Map<String, dynamic> json) {
    final wind = asMapOrNull(json['wind']);
    final airQuality = asMapOrNull(json['air_quality']);
    final lifeIndex = asMapOrNull(json['life_index']);
    final ultraviolet = lifeIndex == null
        ? null
        : asMapOrNull(lifeIndex['ultraviolet']);
    return RealtimeDto(
      temperature: asInt(json['temperature']),
      humidity: asDouble(json['humidity']),
      skycon: asString(json['skycon']),
      pressure: asDouble(json['pressure']),
      apparentTemperature: asDouble(json['apparent_temperature']),
      wind: wind == null ? null : WindDto.fromJson(wind),
      airQuality: airQuality == null
          ? null
          : AirQualityDto.fromJson(airQuality),
      ultravioletIndex: ultraviolet == null
          ? null
          : asInt(ultraviolet['index']),
    );
  }

  final int? temperature;
  final double? humidity;
  final String? skycon;
  final double? pressure;
  final double? apparentTemperature;
  final WindDto? wind;
  final AirQualityDto? airQuality;
  final int? ultravioletIndex;

  RealtimeWeather toEntity() => RealtimeWeather(
    temperature: temperature,
    humidity: humidity,
    skycon: skycon,
    pressure: pressure,
    apparentTemperature: apparentTemperature,
    wind: wind?.toEntity(),
    airQuality: airQuality?.toEntity(),
    ultravioletIndex: ultravioletIndex,
  );
}

class WindDto {
  const WindDto({this.speed, this.direction});

  factory WindDto.fromJson(Map<String, dynamic> json) => WindDto(
    speed: asDouble(json['speed']),
    direction: asDouble(json['direction']),
  );

  final double? speed;
  final double? direction;

  Wind toEntity() => Wind(speed: speed, direction: direction);
}

class AirQualityDto {
  const AirQualityDto({this.pm25, this.aqiChn, this.descriptionChn});

  factory AirQualityDto.fromJson(Map<String, dynamic> json) {
    final aqi = asMap(json['aqi']);
    final description = asMap(json['description']);
    return AirQualityDto(
      pm25: asInt(json['pm25']),
      aqiChn: asInt(aqi['chn']),
      descriptionChn: asString(description['chn']),
    );
  }

  final int? pm25;
  final int? aqiChn;
  final String? descriptionChn;

  AirQuality toEntity() =>
      AirQuality(pm25: pm25, aqiChn: aqiChn, descriptionChn: descriptionChn);
}

class MinutelyDto {
  const MinutelyDto({this.precipitation2h = const <double>[]});

  factory MinutelyDto.fromJson(Map<String, dynamic> json) =>
      MinutelyDto(precipitation2h: asDoubleList(json['precipitation_2h']));

  final List<double> precipitation2h;

  MinutelyWeather toEntity() =>
      MinutelyWeather(precipitation2h: precipitation2h);
}

class HourlyDto {
  const HourlyDto({
    this.temperature = const <HourlyTemperatureDto>[],
    this.skycon = const <HourlySkyconDto>[],
    this.wind = const <HourlyWindDto>[],
    this.aqi = const <HourlyAqiDto>[],
  });

  factory HourlyDto.fromJson(Map<String, dynamic> json) {
    final airQuality = asMap(json['air_quality']);
    return HourlyDto(
      temperature: asMapList(json['temperature'])
          .map(HourlyTemperatureDto.fromJson)
          .toList(growable: false),
      skycon: asMapList(json['skycon'])
          .map(HourlySkyconDto.fromJson)
          .toList(growable: false),
      wind: asMapList(json['wind'])
          .map(HourlyWindDto.fromJson)
          .toList(growable: false),
      aqi: asMapList(airQuality['aqi'])
          .map(HourlyAqiDto.fromJson)
          .toList(growable: false),
    );
  }

  final List<HourlyTemperatureDto> temperature;
  final List<HourlySkyconDto> skycon;
  final List<HourlyWindDto> wind;
  final List<HourlyAqiDto> aqi;

  HourlyWeather toEntity() {
    final forecasts = <HourlyForecast>[];
    for (var i = 0; i < temperature.length; i++) {
      final item = temperature[i];
      forecasts.add(
        HourlyForecast(
          time: item.datetime,
          temperature: item.value ?? 0,
          skycon: i < skycon.length ? (skycon[i].value ?? '') : '',
          windSpeed: i < wind.length ? (wind[i].speed ?? 0) : 0,
          windDirection: i < wind.length ? (wind[i].direction ?? 0) : 0,
          aqi: i < aqi.length ? (aqi[i].value ?? 0) : 0,
        ),
      );
    }
    return HourlyWeather(forecasts: forecasts);
  }
}

class HourlyTemperatureDto {
  const HourlyTemperatureDto({this.datetime, this.value});

  factory HourlyTemperatureDto.fromJson(Map<String, dynamic> json) =>
      HourlyTemperatureDto(
        datetime: asString(json['datetime']),
        value: asInt(json['value']),
      );

  final String? datetime;
  final int? value;
}

class HourlySkyconDto {
  const HourlySkyconDto({this.value});

  factory HourlySkyconDto.fromJson(Map<String, dynamic> json) =>
      HourlySkyconDto(value: asString(json['value']));

  final String? value;
}

class HourlyWindDto {
  const HourlyWindDto({this.speed, this.direction});

  factory HourlyWindDto.fromJson(Map<String, dynamic> json) => HourlyWindDto(
    speed: asDouble(json['speed']),
    direction: asDouble(json['direction']),
  );

  final double? speed;
  final double? direction;
}

class HourlyAqiDto {
  const HourlyAqiDto({this.value});

  factory HourlyAqiDto.fromJson(Map<String, dynamic> json) {
    final value = asMap(json['value']);
    return HourlyAqiDto(value: asInt(value['chn']));
  }

  final int? value;
}
