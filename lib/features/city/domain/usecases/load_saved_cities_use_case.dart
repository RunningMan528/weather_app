/// 模块：读取已保存城市用例（domain）
/// 依赖：core/error/result、core/usecase、本模块实体与仓库契约。
library;

import '../../../../core/error/result.dart';
import '../../../../core/usecase/use_case.dart';
import '../entities/city.dart';
import '../repositories/city_repository.dart';

class LoadSavedCitiesUseCase extends UseCase<List<City>, NoParams> {
  const LoadSavedCitiesUseCase(this._repository);

  final CityRepository _repository;

  @override
  Future<Result<List<City>>> call(NoParams params) =>
      _repository.loadSavedCities();
}
