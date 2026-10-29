/// 模块：天气模块领域实体（天气）
/// 作用：把彩云天气接口返回的数据整理成 UI 可直接消费的业务对象。
/// 设计要点：
///   1) 纯 Dart、不可变，不包含 fromJson/toJson；
///   2) 小时/多天预报在 data 层就已按索引合并成列表，UI 不再处理平行数组；
///   3) 只保留页面真正用到的字段，避免把整个 API 原样搬进领域层。
/// 依赖：纯 Dart。
library;

/// 一次天气查询的完整结果。
class Weather {
  const Weather({
    this.realtime,
    this.minutely,
    this.hourly,
    this.daily,
    this.forecastKeypoint,
    this.location = const <double>[],
  });

  final RealtimeWeather? realtime;
  final MinutelyWeather? minutely;
  final HourlyWeather? hourly;
  final DailyWeather? daily;

  /// 彩云接口的预报摘要，例如"最近的降雨带在东北64公里外呢"。
  final String? forecastKeypoint;

  /// [经度, 纬度]。
  final List<double> location;
}

/// 实时天气。
class RealtimeWeather {
  const RealtimeWeather({
    this.temperature,
    this.humidity,
    this.skycon,
    this.pressure,
    this.apparentTemperature,
    this.wind,
    this.airQuality,
    this.ultravioletIndex,
  });

  final int? temperature;
  final double? humidity;
  final String? skycon;
  final double? pressure;
  final double? apparentTemperature;
  final Wind? wind;
  final AirQuality? airQuality;
  final int? ultravioletIndex;
}

/// 风。
class Wind {
  const Wind({this.speed, this.direction});

  final double? speed;
  final double? direction;
}

/// 空气质量。
class AirQuality {
  const AirQuality({this.pm25, this.aqiChn, this.descriptionChn});

  final int? pm25;
  final int? aqiChn;
  final String? descriptionChn;
}

/// 分钟级降水。
class MinutelyWeather {
  const MinutelyWeather({this.precipitation2h = const <double>[]});

  /// 未来两小时每 5 分钟降水强度，共 24 个点。
  final List<double> precipitation2h;
}

/// 小时预报集合。
class HourlyWeather {
  const HourlyWeather({this.forecasts = const <HourlyForecast>[]});

  final List<HourlyForecast> forecasts;
}

/// 单个小时预报点。
class HourlyForecast {
  const HourlyForecast({
    this.time,
    required this.temperature,
    required this.skycon,
    this.windSpeed = 0,
    this.windDirection = 0,
    this.aqi = 0,
  });

  final String? time;
  final int temperature;
  final String skycon;
  final double windSpeed;
  final double windDirection;
  final int aqi;
}

/// 多天预报集合。
class DailyWeather {
  const DailyWeather({
    this.forecasts = const <DailyForecast>[],
    this.astros = const <Astro>[],
    this.lifeIndex,
  });

  final List<DailyForecast> forecasts;
  final List<Astro> astros;
  final DailyLifeIndex? lifeIndex;
}

/// 单天预报。
class DailyForecast {
  const DailyForecast({
    this.date,
    required this.maxTemperature,
    required this.minTemperature,
    required this.fullSkycon,
    required this.daySkycon,
    required this.nightSkycon,
    this.windSpeed = 0,
    this.windDirection = 0,
    this.aqiMax,
  });

  final String? date;
  final int maxTemperature;
  final int minTemperature;

  /// 全天天气现象。
  final String fullSkycon;

  /// 白天（08:00–20:00）天气现象。
  final String daySkycon;

  /// 夜间（20:00–次日 08:00）天气现象。
  final String nightSkycon;

  final double windSpeed;
  final double windDirection;
  final int? aqiMax;
}

/// 日出日落。
class Astro {
  const Astro({this.date, this.sunrise, this.sunset});

  final String? date;
  final String? sunrise;
  final String? sunset;
}

/// 生活指数集合。
class DailyLifeIndex {
  const DailyLifeIndex({
    this.ultraviolet = const <LifeIndexEntry>[],
    this.carWashing = const <LifeIndexEntry>[],
    this.dressing = const <LifeIndexEntry>[],
    this.comfort = const <LifeIndexEntry>[],
    this.coldRisk = const <LifeIndexEntry>[],
  });

  final List<LifeIndexEntry> ultraviolet;
  final List<LifeIndexEntry> carWashing;
  final List<LifeIndexEntry> dressing;
  final List<LifeIndexEntry> comfort;
  final List<LifeIndexEntry> coldRisk;
}

/// 单条生活指数。
class LifeIndexEntry {
  const LifeIndexEntry({this.date, this.index, this.desc});

  final String? date;
  final String? index;
  final String? desc;
}
