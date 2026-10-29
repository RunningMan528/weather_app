/// 模块：城市 bloc（city/presentation/bloc）
/// 作用：唯一持有"已保存城市 + 当前选中城市"的状态源。
/// 依赖：flutter_bloc + 本模块 domain 用例。
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/city.dart';
import '../../domain/usecases/load_saved_cities_use_case.dart';
import '../../domain/usecases/locate_city_use_case.dart';
import '../../domain/usecases/save_cities_use_case.dart';
import 'city_event.dart';
import 'city_state.dart';

class CityBloc extends Bloc<CityEvent, CityState> {
  CityBloc(this._locateCity, this._loadSavedCities, this._saveCities)
    : super(const CityState()) {
    on<CityStarted>(_onStarted, transformer: _sequential());
    on<CityRelocated>(_onRelocated, transformer: _sequential());
    on<CitySelected>(_onSelected, transformer: _sequential());
    on<CityAdded>(_onAdded, transformer: _sequential());
    on<CityRemoved>(_onRemoved, transformer: _sequential());
  }

  final LocateCityUseCase _locateCity;
  final LoadSavedCitiesUseCase _loadSavedCities;
  final SaveCitiesUseCase _saveCities;

  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

  Future<void> _onStarted(CityStarted event, Emitter<CityState> emit) async {
    emit(const CityState(status: CityStatus.loading));

    final savedResult = await _loadSavedCities(const NoParams());
    final cities = List<City>.of(savedResult.getOrElse(const <City>[]));
    final cityResult = await _locateCity(const NoParams());
    final resolution = cityResult.valueOrNull;

    City? selected;
    var usedFallback = false;
    if (resolution != null) {
      usedFallback = resolution.usedFallback;
      cities.removeWhere(
        (city) => city.isLocated || city.cacheKey == resolution.city.cacheKey,
      );
      cities.insert(0, resolution.city);
      selected = resolution.city;
      await _persistCities(cities);
    } else if (cities.isNotEmpty) {
      selected = cities.first;
    }

    if (selected == null) {
      emit(
        CityState(
          status: CityStatus.error,
          savedCities: cities,
          failure: cityResult.failureOrNull,
        ),
      );
      return;
    }

    emit(
      CityState(
        status: CityStatus.ready,
        savedCities: cities,
        selectedCity: selected,
        usedFallbackCity: usedFallback,
        fallbackReason: resolution?.fallbackReason,
      ),
    );
  }

  Future<void> _onRelocated(
    CityRelocated event,
    Emitter<CityState> emit,
  ) async {
    final previousSelectedCity = state.selectedCity;
    final previousFallback = state.usedFallbackCity;
    final previousFallbackReason = state.fallbackReason;
    // 定位期间清空选中城市，确保即使坐标相同，定位完成后也会触发一次新的天气请求。
    emit(CityState(status: CityStatus.loading, savedCities: state.savedCities));

    final cityResult = await _locateCity(const NoParams());
    final resolution = cityResult.valueOrNull;
    if (resolution == null) {
      emit(
        CityState(
          status: CityStatus.error,
          savedCities: state.savedCities,
          selectedCity: previousSelectedCity,
          failure: cityResult.failureOrNull,
          usedFallbackCity: previousFallback,
          fallbackReason: previousFallbackReason,
        ),
      );
      return;
    }

    final cities = List<City>.of(state.savedCities)
      ..removeWhere(
        (city) => city.isLocated || city.cacheKey == resolution.city.cacheKey,
      )
      ..insert(0, resolution.city);
    await _persistCities(cities);
    emit(
      CityState(
        status: CityStatus.ready,
        savedCities: cities,
        selectedCity: resolution.city,
        usedFallbackCity: resolution.usedFallback,
        fallbackReason: resolution.fallbackReason,
      ),
    );
  }

  Future<void> _onSelected(CitySelected event, Emitter<CityState> emit) async {
    final cities = _ensureCity(state.savedCities, event.city);
    final selected = _existingOrNew(cities, event.city);
    await _persistCities(cities);
    emit(
      CityState(
        status: CityStatus.ready,
        savedCities: cities,
        selectedCity: selected,
        usedFallbackCity: state.usedFallbackCity,
        fallbackReason: state.fallbackReason,
      ),
    );
  }

  Future<void> _onAdded(CityAdded event, Emitter<CityState> emit) async {
    final cities = _ensureCity(state.savedCities, event.city);
    final selected = _existingOrNew(cities, event.city);
    await _persistCities(cities);
    emit(
      CityState(
        status: CityStatus.ready,
        savedCities: cities,
        selectedCity: selected,
        usedFallbackCity: state.usedFallbackCity,
        fallbackReason: state.fallbackReason,
      ),
    );
  }

  Future<void> _onRemoved(CityRemoved event, Emitter<CityState> emit) async {
    if (event.city.isLocated) return;
    final cities = List<City>.of(state.savedCities)
      ..removeWhere((city) => city.cacheKey == event.city.cacheKey);
    if (cities.isEmpty) return;
    await _persistCities(cities);

    final removedSelected = state.selectedCity?.cacheKey == event.city.cacheKey;
    emit(
      CityState(
        status: CityStatus.ready,
        savedCities: cities,
        selectedCity: removedSelected ? cities.first : state.selectedCity,
        usedFallbackCity: state.usedFallbackCity,
        fallbackReason: state.fallbackReason,
      ),
    );
  }

  List<City> _ensureCity(List<City> cities, City city) {
    final result = List<City>.of(cities);
    if (result.every((item) => item.cacheKey != city.cacheKey)) {
      result.add(city);
    }
    return result;
  }

  City _existingOrNew(List<City> cities, City city) {
    for (final item in cities) {
      if (item.cacheKey == city.cacheKey) return item;
    }
    return city;
  }

  Future<void> _persistCities(List<City> cities) async {
    await _saveCities(SaveCitiesParams(cities));
  }
}
