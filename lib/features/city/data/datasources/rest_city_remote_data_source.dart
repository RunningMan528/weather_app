/// 模块：高德城市搜索数据源（data/datasources）
/// 作用：调用 `config/district` 接口按关键词搜索行政区。
/// 依赖：core/error/result、core/network/api_client、data/models。
library;

import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/city_search_result_dto.dart';
import 'city_remote_data_source.dart';

class RestCityRemoteDataSource implements CityRemoteDataSource {
  RestCityRemoteDataSource(
    this._client, {
    required this.baseUrl,
    required this.apiKey,
  });

  final ApiClient _client;
  final String baseUrl;
  final String apiKey;

  @override
  Future<Result<List<CitySearchResultDto>>> searchCities(String keyword) async {
    final result = await _client.get(
      '$baseUrl/config/district',
      query: <String, dynamic>{
        'subdistrict': '1',
        'key': apiKey,
        'keywords': keyword,
      },
    );
    return result.parse(parseCitySearchResults);
  }
}
