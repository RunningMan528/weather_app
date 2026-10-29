/// 模块：城市 DTO（data/models）
/// 作用：解析高德逆地理编码响应，转换成 City 领域实体。
/// 依赖：纯 Dart + 本模块领域实体 + json_helpers。
library;

import '../../domain/entities/city.dart';
import '../../../../core/utils/json_helpers.dart';

class CityDto {
  const CityDto({
    required this.latitude,
    required this.longitude,
    this.country,
    this.province,
    this.city,
    this.district,
    this.poiName,
    this.street,
    this.streetNumber,
    this.isLocated = true,
    required this.displayedName,
  });

  factory CityDto.fromJson(Map<String, dynamic> json) => CityDto(
    latitude: asDouble(json['latitude']) ?? 0,
    longitude: asDouble(json['longitude']) ?? 0,
    country: asString(json['country']),
    province: asString(json['province']),
    city: asString(json['city']),
    district: asString(json['district']),
    poiName: asString(json['poiName']),
    street: asString(json['street']),
    streetNumber: asString(json['streetNumber']),
    isLocated: json['isLocated'] == true,
    displayedName: asString(json['displayedName']) ?? '',
  );

  factory CityDto.fromEntity(City city) => CityDto(
    latitude: city.latitude,
    longitude: city.longitude,
    country: city.country,
    province: city.province,
    city: city.city,
    district: city.district,
    poiName: city.poiName,
    street: city.street,
    streetNumber: city.streetNumber,
    isLocated: city.isLocated,
    displayedName: city.displayedName,
  );

  /// 从高德 `geocode/regeo` 响应构造。
  ///
  /// 直辖市返回的 `city` 可能是空数组，因此 [_textOrFirst] 做了兼容。
  factory CityDto.fromRegeoJson(
    Map<String, dynamic> json, {
    required double latitude,
    required double longitude,
  }) {
    final status = asString(json['status']);
    if (status != null && status != '1') {
      throw FormatException('逆地理编码失败：${asString(json['info']) ?? '未知原因'}');
    }
    final regeocode = asMap(json['regeocode']);
    if (regeocode.isEmpty) {
      throw const FormatException('逆地理编码返回缺少 regeocode');
    }
    final address = asMap(regeocode['addressComponent']);
    final streetNumber = asMap(address['streetNumber']);
    final country = asString(address['country']) ?? '';
    final province = asString(address['province']) ?? '';
    final city = _textOrFirst(address['city']);
    final district = asString(address['district']) ?? '';
    final street = asString(streetNumber['street']) ?? '';
    final number = asString(streetNumber['number']) ?? '';
    final poiName = asString(regeocode['formatted_address']);
    return CityDto(
      latitude: latitude,
      longitude: longitude,
      country: country,
      province: province,
      city: city,
      district: district,
      poiName: poiName,
      street: street,
      streetNumber: number,
      displayedName: _buildDisplayName(
        country: country,
        province: province,
        city: city,
        district: district,
        street: street,
        formattedAddress: poiName ?? '',
      ),
    );
  }

  final double latitude;
  final double longitude;
  final String? country;
  final String? province;
  final String? city;
  final String? district;
  final String? poiName;
  final String? street;
  final String? streetNumber;
  final bool isLocated;
  final String displayedName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'latitude': latitude,
    'longitude': longitude,
    'country': country,
    'province': province,
    'city': city,
    'district': district,
    'poiName': poiName,
    'street': street,
    'streetNumber': streetNumber,
    'isLocated': isLocated,
    'displayedName': displayedName,
  };

  City toEntity() => City(
    latitude: latitude,
    longitude: longitude,
    country: country,
    province: province,
    city: city,
    district: district,
    poiName: poiName,
    street: street,
    streetNumber: streetNumber,
    isLocated: isLocated,
    displayedName: displayedName,
  );

  /// 高德部分字段可能是 String，也可能是空数组。
  static String _textOrFirst(dynamic value) {
    if (value is String) return value;
    if (value is List && value.isNotEmpty) return value.first.toString();
    return '';
  }

  /// 展示名优先"区 + 街道"，与设计图的"雨花台区 龙藏大道"一致。
  static String _buildDisplayName({
    required String country,
    required String province,
    required String city,
    required String district,
    required String street,
    required String formattedAddress,
  }) {
    if (district.isNotEmpty && street.isNotEmpty) {
      return '$district $street';
    }
    if (city.isNotEmpty && district.isNotEmpty) return '$city $district';
    if (district.isNotEmpty) return district;
    if (street.isNotEmpty) return street;
    if (city.isNotEmpty) return city;
    if (province.isNotEmpty) return province;
    // 某些坐标 addressComponent 为空，但 formatted_address 仍然有具体地址。
    if (formattedAddress.isNotEmpty) return formattedAddress;
    if (country.isNotEmpty) return country;
    return '当前位置';
  }
}
