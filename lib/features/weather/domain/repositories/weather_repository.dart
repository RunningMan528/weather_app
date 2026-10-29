/// 模块：天气仓库契约（domain）
/// 作用：定义天气读取/刷新策略：
///   - 普通读取：缓存优先，无缓存才请求网络；
///   - 强制刷新：跳过缓存，网络失败时不静默回退缓存。
/// 依赖：纯 Dart + core/error + 本模块实体 + city/domain 实体。
library;

import '../../../../core/error/result.dart';
import '../../../city/domain/entities/city.dart';
import '../entities/weather.dart';

abstract class WeatherRepository {
  /// 获取天气。
  ///
  /// [forceRefresh] 为 false 时缓存优先，命中缓存不会发网络请求；
  /// 为 true 时强制请求网络，失败直接返回错误（由 UI 决定是否保留旧数据）。
  Future<Result<Weather>> fetchWeather(City city, {bool forceRefresh = false});

  /// 只读取本地缓存。
  Future<Result<Weather?>> readCachedWeather(City city);
}
