/// 模块：定位数据源（city/data/datasources）
/// 作用：封装 geolocator，向仓库层提供纯 `Result<GeoPoint>`。
/// 依赖：dart:async/developer、core/error/result、geolocator、本模块领域实体。
/// 模拟器说明：
///   - iOS Simulator：Features → Location 必须先设置一个位置；
///   - Android Emulator：Extended Controls → Location 必须先发送一个位置；
///   - 否则 getCurrentPosition 会超时，这里会回退到北京并给出具体提示。
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:geolocator/geolocator.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/city.dart';

abstract class LocationDataSource {
  Future<Result<GeoPoint>> getCurrentPosition();
}

/// 基于 geolocator 的实现。
class GeolocatorLocationDataSource implements LocationDataSource {
  const GeolocatorLocationDataSource();

  @override
  Future<Result<GeoPoint>> getCurrentPosition() {
    return Result.guard(
      () async {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw const _LocationException('定位服务未开启（请在系统/模拟器中开启定位）');
        }

        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw const _LocationException('定位权限未授予（请到系统设置中允许定位）');
        }

        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 15),
            ),
          );
          return GeoPoint(
            latitude: position.latitude,
            longitude: position.longitude,
          );
        } on TimeoutException {
          // 实时定位超时时，才回退到上一次已知位置。
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            return GeoPoint(
              latitude: lastKnown.latitude,
              longitude: lastKnown.longitude,
            );
          }
          rethrow;
        }
      },
      onError: (error, stack) {
        developer.log(
          '定位失败: $error',
          name: 'weather.location',
          error: error,
          stackTrace: stack,
        );
        if (error is _LocationException) {
          return UnknownFailure(message: error.message, cause: error);
        }
        if (error is TimeoutException) {
          return TimeoutFailure(
            message: '定位超时（模拟器请先在 Features → Location 设置位置）',
            cause: error,
          );
        }
        if (error is LocationServiceDisabledException) {
          return UnknownFailure(
            message: '定位服务未开启（请在系统/模拟器中开启定位）',
            cause: error,
          );
        }
        if (error is PermissionDeniedException) {
          return UnknownFailure(message: '定位权限被拒绝（请到系统设置中允许定位）', cause: error);
        }
        return UnknownFailure(message: '定位失败：$error', cause: error);
      },
    );
  }
}

class _LocationException implements Exception {
  const _LocationException(this.message);

  final String message;

  @override
  String toString() => 'LocationException: $message';
}
