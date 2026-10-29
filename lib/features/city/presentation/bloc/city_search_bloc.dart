/// 模块：城市搜索 bloc（presentation/bloc）
/// 作用：按关键词调用 domain 用例，输出搜索页四态。
/// 依赖：flutter_bloc、本模块 domain 用例。
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/search_cities_use_case.dart';
import 'city_search_event.dart';
import 'city_search_state.dart';

class CitySearchBloc extends Bloc<CitySearchEvent, CitySearchState> {
  CitySearchBloc(this._searchCities) : super(const CitySearchState()) {
    on<CitySearchKeywordChanged>(_onKeywordChanged, transformer: _sequential());
  }

  final SearchCitiesUseCase _searchCities;

  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

  Future<void> _onKeywordChanged(
    CitySearchKeywordChanged event,
    Emitter<CitySearchState> emit,
  ) async {
    final keyword = event.keyword.trim();
    if (keyword.isEmpty) {
      emit(const CitySearchState());
      return;
    }
    emit(CitySearchState(status: CitySearchStatus.loading, keyword: keyword));
    final result = await _searchCities(SearchCitiesParams(keyword));
    result.when(
      ok: (results) => emit(
        CitySearchState(
          status: results.isEmpty
              ? CitySearchStatus.empty
              : CitySearchStatus.ready,
          keyword: keyword,
          results: results,
        ),
      ),
      err: (failure) => emit(
        CitySearchState(
          status: CitySearchStatus.error,
          keyword: keyword,
          failure: failure,
        ),
      ),
    );
  }
}
