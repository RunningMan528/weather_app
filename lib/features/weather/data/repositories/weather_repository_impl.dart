/// 模块：天气仓库实现（data/repositories）
/// 作用：
///   - 普通读取：缓存优先，命中缓存不发网络；
///   - 强制刷新：跳过缓存请求网络，失败不静默回退缓存；
///   - 无缓存读取：网络成功后回写缓存。
/// 依赖：core/error/result、domain 契约/实体、data 数据源。
library;

import '../../../../core/error/result.dart';
import '../../../city/domain/entities/city.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_local_data_source.dart';
import '../datasources/weather_remote_data_source.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl(this._remote, this._local);

  final WeatherRemoteDataSource _remote;
  final WeatherLocalDataSource _local;

  @override
  Future<Result<Weather>> fetchWeather(
    City city, {
    bool forceRefresh = false,
  }) async {
    // 普通切换城市：有缓存直接返回，不发网络。
    if (!forceRefresh) {
      final cached = await readCachedWeather(city);
      final cachedWeather = cached.valueOrNull;
      if (cachedWeather != null) return Ok<Weather>(cachedWeather);
    }

    final remote = await _remote.fetchWeather(
      longitude: city.longitude,
      latitude: city.latitude,
    );
    if (remote.isOk) {
      final dto = remote.valueOrNull!;
      // 缓存写失败不应影响本次请求成功。
      await _local.save(city.cacheKey, dto.raw);
      return Result.guardSync(dto.toEntity);
    }

    // 强制刷新失败时保留 UI 旧数据并提示错误，不静默回退缓存。
    if (!forceRefresh) {
      final cached = await readCachedWeather(city);
      final cachedWeather = cached.valueOrNull;
      if (cachedWeather != null) return Ok<Weather>(cachedWeather);
    }
    return Err<Weather>(remote.failureOrNull!);
  }

  @override
  Future<Result<Weather?>> readCachedWeather(City city) async {
    final result = await _local.read(city.cacheKey);
    if (result.isErr) return Err<Weather?>(result.failureOrNull!);
    final dto = result.valueOrNull;
    if (dto == null) return const Ok<Weather?>(null);
    return Result.guardSync<Weather?>(dto.toEntity);
  }
}
