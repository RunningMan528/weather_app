/// 模块：天气本地缓存数据源（data/datasources）
/// 作用：把原始天气 JSON 存到 KeyValueStore，供网络失败时降级使用。
/// 依赖：dart:convert、core/error/result、core/storage、data/models。
library;

import 'dart:convert';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/key_value_store.dart';
import '../models/weather_dto.dart';

abstract class WeatherLocalDataSource {
  Future<Result<WeatherDto?>> read(String cityKey);

  Future<Result<void>> save(String cityKey, Map<String, dynamic> json);
}

class KeyValueWeatherLocalDataSource implements WeatherLocalDataSource {
  KeyValueWeatherLocalDataSource(this._store);

  final KeyValueStore _store;

  static const String _prefix = 'weather.cache.';

  @override
  Future<Result<WeatherDto?>> read(String cityKey) {
    return Result.guard(() async {
      final raw = await _store.read('$_prefix$cityKey');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return WeatherDto.fromJson(decoded);
    }, onError: (error, stack) => CacheFailure(cause: error));
  }

  @override
  Future<Result<void>> save(String cityKey, Map<String, dynamic> json) {
    return Result.guard<void>(() async {
      await _store.write('$_prefix$cityKey', jsonEncode(json));
    }, onError: (error, stack) => CacheFailure(cause: error));
  }
}
