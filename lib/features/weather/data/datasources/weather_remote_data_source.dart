/// 模块：天气远程数据源契约（data/datasources）
/// 作用：屏蔽具体 HTTP 实现，只暴露"按经纬度取天气 DTO"。
/// 依赖：core/error/result + data/models。
library;

import '../../../../core/error/result.dart';
import '../models/weather_dto.dart';

abstract class WeatherRemoteDataSource {
  Future<Result<WeatherDto>> fetchWeather({
    required double longitude,
    required double latitude,
  });
}
