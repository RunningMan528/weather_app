/// 模块：高德逆地理编码数据源（data/datasources）
/// 作用：通过 core/network 的 ApiClient 调用高德 regeo 接口。
/// 依赖：core/error/result、core/network/api_client、data/models。
library;

import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/city_dto.dart';
import 'geocode_remote_data_source.dart';

class RestGeocodeRemoteDataSource implements GeocodeRemoteDataSource {
  RestGeocodeRemoteDataSource(
    this._client, {
    required this.baseUrl,
    required this.apiKey,
  });

  final ApiClient _client;

  /// 形如 `https://restapi.amap.com/v3`。
  final String baseUrl;
  final String apiKey;

  @override
  Future<Result<CityDto>> reverseGeocode({
    required double longitude,
    required double latitude,
  }) async {
    final result = await _client.get(
      '$baseUrl/geocode/regeo',
      query: <String, dynamic>{
        'key': apiKey,
        'location': '$longitude,$latitude',
      },
    );
    return result.parse(
      (json) =>
          CityDto.fromRegeoJson(json, longitude: longitude, latitude: latitude),
    );
  }
}
