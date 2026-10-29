/// 模块：城市功能测试
/// 覆盖：高德 district 递归摊平/去重、CityDto 本地序列化往返。
/// 运行：flutter test test/features/city/city_feature_test.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/city/data/models/city_dto.dart';
import 'package:weather_app/features/city/data/models/city_search_result_dto.dart';
import 'package:weather_app/features/city/domain/entities/city.dart';

void main() {
  group('CitySearchResultDto', () {
    test('递归摊平省/市/区并去重', () {
      final results = parseCitySearchResults(_districtResponse());

      expect(results.length, 3);
      expect(
        results.map((item) => item.name),
        containsAll(<String>['北京市', '东城区', '西城区']),
      );
      expect(results.first.longitude, 116.407526);
      expect(results.first.latitude, 39.90403);
    });
  });

  group('CityDto', () {
    test('本地序列化往返保留展示名与定位标记', () {
      const city = City(
        latitude: 39.904989,
        longitude: 116.405285,
        country: '中国',
        province: '北京市',
        city: '北京市',
        district: '东城区',
        street: '东长安街',
        streetNumber: '1号',
        isLocated: true,
        displayedName: '东城区 东长安街',
      );

      final json = CityDto.fromEntity(city).toJson();
      final restored = CityDto.fromJson(json).toEntity();

      expect(restored.displayedName, city.displayedName);
      expect(restored.isLocated, isTrue);
      expect(restored.cacheKey, city.cacheKey);
    });
  });
}

Map<String, dynamic> _districtResponse() => <String, dynamic>{
  'status': '1',
  'info': 'OK',
  'districts': <Map<String, dynamic>>[
    <String, dynamic>{
      'name': '北京市',
      'center': '116.407526,39.90403',
      'level': 'province',
      'districts': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': '东城区',
          'center': '116.418757,39.917544',
          'level': 'district',
        },
        <String, dynamic>{
          'name': '西城区',
          'center': '116.366794,39.915309',
          'level': 'district',
        },
        <String, dynamic>{
          'name': '北京市',
          'center': '116.407526,39.90403',
          'level': 'province',
        },
      ],
    },
  ],
};
