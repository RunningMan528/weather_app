/// 模块：依赖装配（app/di）
/// 作用：composition root——按"基础设施 → 数据源 → 仓库 → 用例 → bloc"顺序注册依赖。
/// 依赖：全部 feature 的构造函数（只有这一层 import 具体实现）。
/// 跨 feature 说明：
///   - weather/domain 依赖 city/domain（天气需要 City）；
///   - city/domain 通过 CityWeatherSummaryProvider 端口拿到摘要，
///     由 weather/data 的 WeatherSummaryProviderImpl 实现，避免 city → weather 反向依赖。
library;

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/monitoring/monitoring_service.dart';
import '../../core/monitoring/noop_monitoring_service.dart';
import '../../core/monitoring/sentry_monitoring_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/network/dio_api_client.dart';
import '../../core/network/dio_client_factory.dart';
import '../../core/network/token_provider.dart';
import '../../core/storage/key_value_store.dart';
import '../../core/storage/shared_preferences_key_value_store.dart';
import '../../features/city/data/datasources/city_local_data_source.dart';
import '../../features/city/data/datasources/city_remote_data_source.dart';
import '../../features/city/data/datasources/geocode_remote_data_source.dart';
import '../../features/city/data/datasources/location_data_source.dart';
import '../../features/city/data/datasources/rest_city_remote_data_source.dart';
import '../../features/city/data/datasources/rest_geocode_remote_data_source.dart';
import '../../features/city/data/repositories/city_repository_impl.dart';
import '../../features/city/domain/repositories/city_repository.dart';
import '../../features/city/domain/repositories/city_weather_summary_provider.dart';
import '../../features/city/domain/usecases/load_city_weather_summaries_use_case.dart';
import '../../features/city/domain/usecases/load_saved_cities_use_case.dart';
import '../../features/city/domain/usecases/locate_city_use_case.dart';
import '../../features/city/domain/usecases/save_cities_use_case.dart';
import '../../features/city/domain/usecases/search_cities_use_case.dart';
import '../../features/city/presentation/bloc/city_bloc.dart';
import '../../features/city/presentation/bloc/city_manager_bloc.dart';
import '../../features/city/presentation/bloc/city_search_bloc.dart';
import '../../features/weather/data/datasources/rest_weather_remote_data_source.dart';
import '../../features/weather/data/datasources/weather_local_data_source.dart';
import '../../features/weather/data/datasources/weather_remote_data_source.dart';
import '../../features/weather/data/repositories/weather_repository_impl.dart';
import '../../features/weather/data/repositories/weather_summary_provider_impl.dart';
import '../../features/weather/domain/repositories/weather_repository.dart';
import '../../features/weather/domain/usecases/load_cached_weather_use_case.dart';
import '../../features/weather/domain/usecases/load_weather_use_case.dart';
import '../../features/weather/presentation/bloc/weather_bloc.dart';
import 'service_locator.dart';

ServiceLocator buildDependencyGraph({
  AppConfig config = AppConfig.fromEnvironment,
  KeyValueStore? keyValueStore,
}) {
  final locator = ServiceLocator();

  // ---------------------------------------------------------------- core：监控
  // 可插拔：关闭 Sentry 时自动使用 Noop；测试也可直接注册 NoopMonitoringService。
  locator.registerSingleton<MonitoringService>(
    config.sentryEnabled
        ? SentryMonitoringService(config)
        : const NoopMonitoringService(),
  );

  // ---------------------------------------------------------------- core：存储
  locator.registerLazySingleton<KeyValueStore>(
    () => keyValueStore ?? SharedPreferencesKeyValueStore(),
  );

  // ---------------------------------------------------------------- core：网络
  locator.registerSingleton<TokenProvider>(const _AnonymousTokenProvider());
  locator.registerLazySingleton<Dio>(
    () => buildDio(
      config: ApiConfig(
        baseUrl: config.caiyunBaseUrl,
        enableLogging: config.enableHttpLogging,
      ),
      tokenProvider: locator.get<TokenProvider>(),
    ),
  );
  locator.registerLazySingleton<ApiClient>(
    () => DioApiClient(locator.get<Dio>()),
  );

  // ---------------------------------------------------------------- city：数据源
  locator.registerLazySingleton<CityRemoteDataSource>(
    () => RestCityRemoteDataSource(
      locator.get<ApiClient>(),
      baseUrl: config.amapBaseUrl,
      apiKey: config.amapKey,
    ),
  );
  locator.registerLazySingleton<CityLocalDataSource>(
    () => KeyValueCityLocalDataSource(locator.get<KeyValueStore>()),
  );
  locator.registerLazySingleton<LocationDataSource>(
    () => const GeolocatorLocationDataSource(),
  );
  locator.registerLazySingleton<GeocodeRemoteDataSource>(
    () => RestGeocodeRemoteDataSource(
      locator.get<ApiClient>(),
      baseUrl: config.amapBaseUrl,
      apiKey: config.amapKey,
    ),
  );

  // ---------------------------------------------------------------- weather：数据源
  locator.registerLazySingleton<WeatherRemoteDataSource>(
    () => RestWeatherRemoteDataSource(
      locator.get<ApiClient>(),
      baseUrl: config.caiyunBaseUrl,
    ),
  );
  locator.registerLazySingleton<WeatherLocalDataSource>(
    () => KeyValueWeatherLocalDataSource(locator.get<KeyValueStore>()),
  );

  // ---------------------------------------------------------------- 仓库
  locator.registerLazySingleton<CityRepository>(
    () => CityRepositoryImpl(
      locator.get<LocationDataSource>(),
      locator.get<GeocodeRemoteDataSource>(),
      locator.get<CityRemoteDataSource>(),
      locator.get<CityLocalDataSource>(),
    ),
  );
  locator.registerLazySingleton<WeatherRepository>(
    () => WeatherRepositoryImpl(
      locator.get<WeatherRemoteDataSource>(),
      locator.get<WeatherLocalDataSource>(),
    ),
  );

  // ---------------------------------------------------------------- 跨 feature 端口
  // city/domain 声明端口；weather/data 提供适配器实现。
  locator.registerLazySingleton<CityWeatherSummaryProvider>(
    () => WeatherSummaryProviderImpl(locator.get<WeatherRepository>()),
  );

  // ---------------------------------------------------------------- city：用例
  locator.registerLazySingleton(
    () => LocateCityUseCase(locator.get<CityRepository>()),
  );
  locator.registerLazySingleton(
    () => LoadSavedCitiesUseCase(locator.get<CityRepository>()),
  );
  locator.registerLazySingleton(
    () => SaveCitiesUseCase(locator.get<CityRepository>()),
  );
  locator.registerLazySingleton(
    () => SearchCitiesUseCase(locator.get<CityRepository>()),
  );
  locator.registerLazySingleton(
    () => LoadCityWeatherSummariesUseCase(
      locator.get<CityWeatherSummaryProvider>(),
    ),
  );

  // ---------------------------------------------------------------- weather：用例
  locator.registerLazySingleton(
    () => LoadWeatherUseCase(locator.get<WeatherRepository>()),
  );
  locator.registerLazySingleton(
    () => LoadCachedWeatherUseCase(locator.get<WeatherRepository>()),
  );

  // ---------------------------------------------------------------- bloc
  locator.registerFactory<CityBloc>(
    () => CityBloc(
      locator.get<LocateCityUseCase>(),
      locator.get<LoadSavedCitiesUseCase>(),
      locator.get<SaveCitiesUseCase>(),
    ),
  );
  locator.registerFactory<WeatherBloc>(
    () => WeatherBloc(
      locator.get<LoadWeatherUseCase>(),
      locator.get<LoadCachedWeatherUseCase>(),
    ),
  );
  locator.registerFactory<CitySearchBloc>(
    () => CitySearchBloc(locator.get<SearchCitiesUseCase>()),
  );
  locator.registerFactory<CityManagerBloc>(
    () => CityManagerBloc(locator.get<LoadCityWeatherSummariesUseCase>()),
  );

  return locator;
}

/// 无鉴权场景的令牌提供者。
class _AnonymousTokenProvider implements TokenProvider {
  const _AnonymousTokenProvider();

  @override
  String? get accessToken => null;
}
