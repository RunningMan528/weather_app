/// 模块：城市搜索状态（presentation/bloc）
/// 依赖：core/error + 本模块领域实体。
library;

import '../../../../core/error/failure.dart';
import '../../domain/entities/city.dart';

enum CitySearchStatus { idle, loading, ready, empty, error }

class CitySearchState {
  const CitySearchState({
    this.status = CitySearchStatus.idle,
    this.keyword = '',
    this.results = const <CitySearchResult>[],
    this.failure,
  });

  final CitySearchStatus status;
  final String keyword;
  final List<CitySearchResult> results;
  final Failure? failure;
}
