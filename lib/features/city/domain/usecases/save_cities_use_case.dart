/// 模块：保存城市列表用例（domain）
/// 依赖：core/error/result、core/usecase、本模块实体与仓库契约。
library;

import '../../../../core/error/result.dart';
import '../../../../core/usecase/use_case.dart';
import '../entities/city.dart';
import '../repositories/city_repository.dart';

class SaveCitiesParams {
  const SaveCitiesParams(this.cities);

  final List<City> cities;
}

class SaveCitiesUseCase extends UseCase<void, SaveCitiesParams> {
  const SaveCitiesUseCase(this._repository);

  final CityRepository _repository;

  @override
  Future<Result<void>> call(SaveCitiesParams params) =>
      _repository.saveCities(params.cities);
}
