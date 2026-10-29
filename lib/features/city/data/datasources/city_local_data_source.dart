/// 模块：城市本地存储数据源（data/datasources）
/// 作用：把已保存城市列表写入 KeyValueStore。
/// 依赖：dart:convert、core/error/result、core/storage、data/models。
library;

import 'dart:convert';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/key_value_store.dart';
import '../models/city_dto.dart';

abstract class CityLocalDataSource {
  Future<Result<List<CityDto>>> read();

  Future<Result<void>> write(List<CityDto> cities);
}

class KeyValueCityLocalDataSource implements CityLocalDataSource {
  KeyValueCityLocalDataSource(this._store);

  final KeyValueStore _store;

  static const String _key = 'weather.saved_cities';

  @override
  Future<Result<List<CityDto>>> read() {
    return Result.guard(() async {
      final raw = await _store.read(_key);
      if (raw == null || raw.isEmpty) return <CityDto>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <CityDto>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CityDto.fromJson)
          .toList(growable: false);
    }, onError: (error, stack) => CacheFailure(cause: error));
  }

  @override
  Future<Result<void>> write(List<CityDto> cities) {
    return Result.guard<void>(() async {
      final raw = jsonEncode(
        cities.map((city) => city.toJson()).toList(growable: false),
      );
      await _store.write(_key, raw);
    }, onError: (error, stack) => CacheFailure(cause: error));
  }
}
