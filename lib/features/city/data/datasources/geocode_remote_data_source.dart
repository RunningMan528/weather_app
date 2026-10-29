/// 模块：逆地理编码数据源契约（data/datasources）
/// 作用：把经纬度解析成城市/区/街道信息。
/// 依赖：core/error/result + data/models。
library;

import '../../../../core/error/result.dart';
import '../models/city_dto.dart';

abstract class GeocodeRemoteDataSource {
  Future<Result<CityDto>> reverseGeocode({
    required double longitude,
    required double latitude,
  });
}
