/// 模块：定位城市用例（domain）
/// 作用：调用城市仓库解析当前位置，供首页加载时使用。
/// 依赖：core/usecase、本模块实体与仓库契约。
library;

import '../../../../core/error/result.dart';
import '../../../../core/usecase/use_case.dart';
import '../entities/city.dart';
import '../repositories/city_repository.dart';

/// 定位城市用例。
class LocateCityUseCase extends UseCase<CityResolution, NoParams> {
  const LocateCityUseCase(this._repository);

  final CityRepository _repository;

  @override
  Future<Result<CityResolution>> call(NoParams params) =>
      _repository.resolveCurrentCity();
}
