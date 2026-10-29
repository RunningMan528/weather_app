/// 模块：天气 bloc（weather/presentation/bloc）
/// 作用：
///   - 切换城市：优先内存缓存 → 本地缓存；都没有才 loading + 请求网络；
///   - 城市列表变化：预读各城市本地缓存，供 PageView 每页立即渲染；
///   - 下拉刷新：强制请求网络，保留旧数据直到成功/失败。
/// 依赖：flutter_bloc + city/domain + weather/domain 用例。
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../city/domain/entities/city.dart';
import '../../domain/entities/weather.dart';
import '../../domain/usecases/load_cached_weather_use_case.dart';
import '../../domain/usecases/load_weather_use_case.dart';
import 'weather_event.dart';
import 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc(this._loadWeather, this._loadCachedWeather)
    : super(const WeatherState()) {
    on<WeatherRequested>(_onRequested, transformer: _sequential());
    on<WeatherRefreshed>(_onRefreshed, transformer: _sequential());
    on<WeatherCachesPrepared>(_onCachesPrepared, transformer: _sequential());
  }

  final LoadWeatherUseCase _loadWeather;
  final LoadCachedWeatherUseCase _loadCachedWeather;

  /// 进程内天气缓存：key 为 city.cacheKey。
  final Map<String, Weather> _weatherByCity = <String, Weather>{};

  /// 供 PageView 每页读取天气数据。
  Weather? weatherFor(City city) => _weatherByCity[city.cacheKey];

  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

  Future<void> _onRequested(
    WeatherRequested event,
    Emitter<WeatherState> emit,
  ) async {
    // 1) 内存缓存命中：直接展示，不发任何请求。
    final inMemory = _weatherByCity[event.city.cacheKey];
    if (inMemory != null) {
      emit(
        WeatherState(
          status: WeatherStatus.ready,
          city: event.city,
          weather: inMemory,
        ),
      );
      return;
    }

    // 2) 本地缓存命中：直接展示，不发网络。
    final cachedResult = await _loadCachedWeather(
      LoadCachedWeatherParams(event.city),
    );
    final cachedWeather = cachedResult.valueOrNull;
    if (cachedWeather != null) {
      _weatherByCity[event.city.cacheKey] = cachedWeather;
      emit(
        WeatherState(
          status: WeatherStatus.ready,
          city: event.city,
          weather: cachedWeather,
        ),
      );
      return;
    }

    // 3) 无缓存：加载动画 + 请求网络。
    emit(WeatherState(status: WeatherStatus.loading, city: event.city));
    await _load(emit, event.city, forceRefresh: false);
  }

  Future<void> _onRefreshed(
    WeatherRefreshed event,
    Emitter<WeatherState> emit,
  ) async {
    final city = state.city;
    if (city == null) return;
    // 下拉刷新：不额外 emit loading（RefreshIndicator 自带动画），
    // 只在网络成功/失败时更新状态，减少一次整页 rebuild。
    await _load(emit, city, forceRefresh: true);
  }

  Future<void> _onCachesPrepared(
    WeatherCachesPrepared event,
    Emitter<WeatherState> emit,
  ) async {
    final keys = event.cities.map((city) => city.cacheKey).toSet();
    _weatherByCity.removeWhere((key, _) => !keys.contains(key));
    for (final city in event.cities) {
      if (_weatherByCity.containsKey(city.cacheKey)) continue;
      final result = await _loadCachedWeather(LoadCachedWeatherParams(city));
      final weather = result.valueOrNull;
      if (weather != null) _weatherByCity[city.cacheKey] = weather;
    }
    // 触发 PageView 重建，让已预读的页面立即显示天气。
    emit(
      WeatherState(
        status: state.status,
        city: state.city,
        weather: state.weather,
        failure: state.failure,
      ),
    );
  }

  Future<void> _load(
    Emitter<WeatherState> emit,
    City city, {
    required bool forceRefresh,
  }) async {
    final previousWeather = state.weather;
    final result = await _loadWeather(
      LoadWeatherParams(city: city, forceRefresh: forceRefresh),
    );
    result.when(
      ok: (weather) {
        _weatherByCity[city.cacheKey] = weather;
        emit(
          WeatherState(
            status: WeatherStatus.ready,
            city: city,
            weather: weather,
          ),
        );
      },
      err: (failure) => emit(
        WeatherState(
          status: WeatherStatus.error,
          city: city,
          weather: previousWeather,
          failure: failure,
        ),
      ),
    );
  }
}
