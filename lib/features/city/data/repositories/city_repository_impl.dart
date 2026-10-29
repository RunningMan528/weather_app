/// 模块：城市仓库实现（data/repositories）
/// 作用：定位、逆地理编码、读写已保存城市、搜索行政区。
/// 依赖：core/error/result、domain 契约/实体、data 数据源。
library;

import 'dart:developer' as developer;

import '../../../../core/error/result.dart';
import '../../domain/entities/city.dart';
import '../../domain/repositories/city_repository.dart';
import '../datasources/city_local_data_source.dart';
import '../datasources/city_remote_data_source.dart';
import '../datasources/geocode_remote_data_source.dart';
import '../datasources/location_data_source.dart';
import '../models/city_dto.dart';

class CityRepositoryImpl implements CityRepository {
  CityRepositoryImpl(this._location, this._geocode, this._remote, this._local);

  final LocationDataSource _location;
  final GeocodeRemoteDataSource _geocode;
  final CityRemoteDataSource _remote;
  final CityLocalDataSource _local;

  @override
  Future<Result<CityResolution>> resolveCurrentCity() async {
    final positionResult = await _location.getCurrentPosition();
    if (positionResult.isErr) {
      // 定位失败：使用北京兜底，并把具体原因带到 UI。
      return Ok<CityResolution>(
        CityResolution(
          city: City.beijing,
          usedFallback: true,
          fallbackReason: positionResult.failureOrNull?.message,
        ),
      );
    }
    final point = positionResult.valueOrNull!;
    final geocodeResult = await _geocode.reverseGeocode(
      longitude: point.longitude,
      latitude: point.latitude,
    );
    if (geocodeResult.isErr) {
      developer.log(
        '逆地理编码失败: ${geocodeResult.failureOrNull?.message}',
        name: 'weather.geocode',
        error: geocodeResult.failureOrNull?.cause,
      );
    }
    final city =
        geocodeResult.valueOrNull?.toEntity() ??
        City(
          latitude: point.latitude,
          longitude: point.longitude,
          isLocated: true,
          displayedName: '当前位置',
        );
    return Ok<CityResolution>(CityResolution(city: city, usedFallback: false));
  }

  @override
  Future<Result<List<City>>> loadSavedCities() async {
    final result = await _local.read();
    return result.map(
      (dtos) => dtos.map((dto) => dto.toEntity()).toList(growable: false),
    );
  }

  @override
  Future<Result<void>> saveCities(List<City> cities) {
    return _local.write(cities.map(CityDto.fromEntity).toList(growable: false));
  }

  @override
  Future<Result<List<CitySearchResult>>> searchCities(String keyword) async {
    final result = await _remote.searchCities(keyword);
    return result.map(
      (dtos) => dtos
          .map((dto) => dto.toEntity())
          .whereType<CitySearchResult>()
          .toList(growable: false),
    );
  }
}
