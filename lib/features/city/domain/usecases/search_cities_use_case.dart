/// 模块：搜索城市用例（domain）
/// 依赖：core/error/result、core/usecase、本模块实体与仓库契约。
library;

import '../../../../core/error/result.dart';
import '../../../../core/usecase/use_case.dart';
import '../entities/city.dart';
import '../repositories/city_repository.dart';

class SearchCitiesParams {
  const SearchCitiesParams(this.keyword);

  final String keyword;
}

class SearchCitiesUseCase
    extends UseCase<List<CitySearchResult>, SearchCitiesParams> {
  const SearchCitiesUseCase(this._repository);

  final CityRepository _repository;

  @override
  Future<Result<List<CitySearchResult>>> call(SearchCitiesParams params) {
    final keyword = params.keyword.trim();
    if (keyword.isEmpty) {
      return Future<Result<List<CitySearchResult>>>.value(
        const Ok<List<CitySearchResult>>(<CitySearchResult>[]),
      );
    }
    return _repository.searchCities(keyword);
  }
}
