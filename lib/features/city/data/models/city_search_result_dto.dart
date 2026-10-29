/// 模块：城市搜索结果 DTO（data/models）
/// 作用：解析高德 district 接口，并递归摊平省/市/区结果。
/// 依赖：纯 Dart + 本模块领域实体 + json_helpers。
library;

import '../../domain/entities/city.dart';
import '../../../../core/utils/json_helpers.dart';

class CitySearchResultDto {
  const CitySearchResultDto({
    required this.name,
    this.longitude,
    this.latitude,
    required this.level,
  });

  factory CitySearchResultDto.fromJson(Map<String, dynamic> json) {
    final center = asString(json['center']) ?? '';
    final parts = center.split(',');
    return CitySearchResultDto(
      name: asString(json['name']) ?? '',
      longitude: parts.isNotEmpty ? double.tryParse(parts[0]) : null,
      latitude: parts.length > 1 ? double.tryParse(parts[1]) : null,
      level: asString(json['level']) ?? '',
    );
  }

  final String name;
  final double? longitude;
  final double? latitude;
  final String level;

  CitySearchResult? toEntity() {
    final lng = longitude;
    final lat = latitude;
    if (name.isEmpty || lng == null || lat == null) return null;
    return CitySearchResult(
      name: name,
      longitude: lng,
      latitude: lat,
      level: level,
    );
  }
}

/// 把高德 district 响应的 `districts` 及其子级递归摊平。
List<CitySearchResultDto> parseCitySearchResults(Map<String, dynamic> json) {
  final status = asString(json['status']);
  if (status != null && status != '1') {
    throw FormatException('城市搜索失败：${asString(json['info']) ?? '未知原因'}');
  }
  final results = <CitySearchResultDto>[];
  final seen = <String>{};

  void collect(dynamic value) {
    for (final item in asMapList(value)) {
      final dto = CitySearchResultDto.fromJson(item);
      if (dto.name.isNotEmpty &&
          dto.longitude != null &&
          dto.latitude != null) {
        final key = '${dto.name},${dto.longitude},${dto.latitude}';
        if (seen.add(key)) results.add(dto);
      }
      collect(item['districts']);
    }
  }

  collect(json['districts']);
  return results;
}
