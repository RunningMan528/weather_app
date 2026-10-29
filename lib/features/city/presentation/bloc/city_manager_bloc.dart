/// 模块：城市管理 bloc（city/presentation/bloc）
/// 作用：批量读取城市天气摘要，供城市管理卡片展示。
/// 依赖：flutter_bloc + 本模块 domain 用例。
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/load_city_weather_summaries_use_case.dart';
import 'city_manager_event.dart';
import 'city_manager_state.dart';

class CityManagerBloc extends Bloc<CityManagerEvent, CityManagerState> {
  CityManagerBloc(this._loadSummaries) : super(const CityManagerState()) {
    on<CityManagerSummariesRequested>(
      _onSummariesRequested,
      transformer: _sequential(),
    );
  }

  final LoadCityWeatherSummariesUseCase _loadSummaries;

  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

  Future<void> _onSummariesRequested(
    CityManagerSummariesRequested event,
    Emitter<CityManagerState> emit,
  ) async {
    emit(CityManagerState(summaries: state.summaries, isLoading: true));
    final result = await _loadSummaries(
      CityWeatherSummariesParams(event.cities),
    );
    result.when(
      ok: (summaries) => emit(CityManagerState(summaries: summaries)),
      err: (failure) =>
          emit(CityManagerState(summaries: state.summaries, failure: failure)),
    );
  }
}
