/// 模块：彩云天气远程数据源（data/datasources）
/// 作用：通过 core/network 的 ApiClient 调用彩云天气接口，返回 WeatherDto。
/// 依赖：core/error/result、core/network/api_client、data/models。
library;

import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/weather_dto.dart';
import 'weather_remote_data_source.dart';

class RestWeatherRemoteDataSource implements WeatherRemoteDataSource {
  RestWeatherRemoteDataSource(this._client, {required this.baseUrl});

  final ApiClient _client;

  /// 形如 `https://api.caiyunapp.com/v2.5/<token>/`。
  final String baseUrl;

  @override
  Future<Result<WeatherDto>> fetchWeather({
    required double longitude,
    required double latitude,
  }) async {
    // 绝对 URL 会覆盖 Dio 的 baseUrl，便于同一 ApiClient 访问多个开放平台。
    final url = '$baseUrl$longitude,$latitude/weather.json';
    final result = await _client.get(url);
    return result.parse(WeatherDto.fromJson);
  }
}
