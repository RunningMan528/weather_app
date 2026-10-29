/// 模块：城市仓库契约（domain）
/// 作用：定位当前城市、读写已保存城市、搜索行政区。
/// 依赖：纯 Dart + core/error + 本模块实体。
library;

import '../../../../core/error/result.dart';
import '../entities/city.dart';

abstract class CityRepository {
  /// 定位当前城市并做逆地理编码；失败时返回北京作为兜底城市。
  Future<Result<CityResolution>> resolveCurrentCity();

  /// 读取已保存城市列表。
  Future<Result<List<City>>> loadSavedCities();

  /// 覆盖保存城市列表。
  Future<Result<void>> saveCities(List<City> cities);

  /// 按关键词搜索城市/行政区。
  Future<Result<List<CitySearchResult>>> searchCities(String keyword);
}
