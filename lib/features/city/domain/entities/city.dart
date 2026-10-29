/// 模块：天气模块领域实体（城市）
/// 作用：表达"要查询哪个城市"的业务语义，不包含 JSON、Flutter 或网络细节。
/// 依赖：纯 Dart。
library;

/// 经纬度坐标。
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}

/// 城市/位置实体。
class City {
  const City({
    required this.latitude,
    required this.longitude,
    this.country,
    this.province,
    this.city,
    this.district,
    this.poiName,
    this.street,
    this.streetNumber,
    this.isLocated = false,
    required this.displayedName,
  });

  /// 定位失败时的兜底城市（北京）。
  static const City beijing = City(
    latitude: 39.904989,
    longitude: 116.405285,
    country: '中国',
    province: '北京市',
    city: '北京市',
    district: '东城区',
    displayedName: '北京市',
  );

  final double latitude;
  final double longitude;
  final String? country;
  final String? province;
  final String? city;
  final String? district;
  final String? poiName;
  final String? street;
  final String? streetNumber;

  /// 是否为 GPS 定位得到的城市。
  final bool isLocated;

  /// 顶部栏展示名称。
  final String displayedName;

  /// 缓存键：经纬度足够唯一，保留小数避免过长。
  String get cacheKey =>
      '${longitude.toStringAsFixed(4)},${latitude.toStringAsFixed(4)}';

  @override
  String toString() => 'City($displayedName, $latitude, $longitude)';
}

/// 城市解析结果：区分"定位成功"与"定位失败后用默认城市"。
class CityResolution {
  const CityResolution({
    required this.city,
    required this.usedFallback,
    this.fallbackReason,
  });

  final City city;
  final bool usedFallback;

  /// 定位失败回退时的具体原因（用于 UI 提示与排障）。
  final String? fallbackReason;
}

/// 城市搜索结果（高德 district 接口返回的行政区）。
class CitySearchResult {
  const CitySearchResult({
    required this.name,
    required this.longitude,
    required this.latitude,
    required this.level,
  });

  final String name;
  final double longitude;
  final double latitude;

  /// city / district / province 等。
  final String level;

  /// 搜索结果转成可保存的城市实体。
  City toCity() => City(
    latitude: latitude,
    longitude: longitude,
    displayedName: name,
    isLocated: false,
  );
}
