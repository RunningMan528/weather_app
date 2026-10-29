/// 模块：城市搜索远程数据源契约（data/datasources）
/// 依赖：core/error/result + data/models。
library;

import '../../../../core/error/result.dart';
import '../models/city_search_result_dto.dart';

abstract class CityRemoteDataSource {
  Future<Result<List<CitySearchResultDto>>> searchCities(String keyword);
}
