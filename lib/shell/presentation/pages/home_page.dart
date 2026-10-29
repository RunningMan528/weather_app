/// 模块：首页主壳（shell/presentation/pages）
/// 作用：组合 CityBloc（城市/定位）与 WeatherBloc（天气），并负责跨 feature 协调。
/// 性能要点：
///   - 顶栏只订阅 CityBloc；
///   - 背景只订阅"选中城市 + 天气类型"，并用 RepaintBoundary 隔离粒子动画；
///   - PageView 内容区才同时订阅 CityBloc + WeatherBloc。
/// 依赖：city/weather 两个 feature 的 presentation 公共组件与 bloc（仅 shell 组合层允许）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/city/presentation/bloc/city_bloc.dart';
import '../../../features/city/presentation/bloc/city_event.dart';
import '../../../features/city/presentation/bloc/city_state.dart';
import '../../../features/city/presentation/city_routes.dart';
import '../../../features/weather/presentation/bloc/weather_bloc.dart';
import '../../../features/weather/presentation/bloc/weather_event.dart';
import '../../../features/weather/presentation/bloc/weather_state.dart';
import '../../../features/weather/presentation/utils/weather_style.dart';
import '../../../features/weather/presentation/widgets/weather_content.dart';
import '../../../features/weather/presentation/widgets/weather_main_bg.dart';
import '../../../features/weather/presentation/widgets/weather_status_view.dart';
import '../widgets/home_top_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  bool _syncingPage = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 由圆点/城市管理/列表变化触发：把 PageView 同步到选中城市。
  Future<void> _syncPage(CityState state) async {
    if (state.savedCities.isEmpty) return;
    final index = state.selectedIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_pageController.hasClients) return;
      final currentPage = _pageController.page?.round() ?? 0;
      if (currentPage == index) return;
      _syncingPage = true;
      try {
        await _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      } finally {
        _syncingPage = false;
      }
    });
  }

  /// 用户左右滑动结束后，按当前页切换城市。
  void _handlePageSettled(CityState cityState) {
    if (_syncingPage || !_pageController.hasClients) return;
    final page = _pageController.page?.round();
    if (page == null || page < 0 || page >= cityState.savedCities.length) {
      return;
    }
    final city = cityState.savedCities[page];
    if (city.cacheKey == cityState.selectedCity?.cacheKey) return;
    context.read<CityBloc>().add(CitySelected(city));
  }

  bool _citiesChanged(CityState previous, CityState current) {
    if (previous.savedCities.length != current.savedCities.length) return true;
    for (var i = 0; i < previous.savedCities.length; i++) {
      if (previous.savedCities[i].cacheKey != current.savedCities[i].cacheKey) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CityBloc, CityState>(
      listenWhen: (previous, current) =>
          previous.usedFallbackCity != current.usedFallbackCity,
      listener: (context, state) {
        if (!state.usedFallbackCity) return;
        final reason = state.fallbackReason;
        final message = reason == null || reason.trim().isEmpty
            ? '定位失败，已使用默认城市'
            : '定位失败（$reason），已使用默认城市';
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      child: BlocListener<CityBloc, CityState>(
        listenWhen: _citiesChanged,
        listener: (context, state) {
          if (state.savedCities.isEmpty) return;
          context.read<WeatherBloc>().add(
            WeatherCachesPrepared(state.savedCities),
          );
        },
        child: BlocListener<CityBloc, CityState>(
          listenWhen: (previous, current) =>
              previous.selectedCity?.cacheKey != current.selectedCity?.cacheKey,
          listener: (context, state) {
            final city = state.selectedCity;
            if (city == null) return;
            context.read<WeatherBloc>().add(WeatherRequested(city));
          },
          child: BlocListener<CityBloc, CityState>(
            listenWhen: (previous, current) =>
                previous.selectedIndex != current.selectedIndex ||
                previous.savedCities.length != current.savedCities.length,
            listener: (context, state) => _syncPage(state),
            child: BlocListener<WeatherBloc, WeatherState>(
              listenWhen: (previous, current) =>
                  current.status == WeatherStatus.error &&
                  current.weather != null &&
                  previous.failure != current.failure,
              listener: (context, state) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(state.failure?.userMessage ?? '刷新失败'),
                    ),
                  );
              },
              child: Scaffold(
                backgroundColor: const Color(0xFF0071D1),
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    const RepaintBoundary(child: _HomeBackground()),
                    SafeArea(
                      child: Column(
                        children: [
                          const _HomeTopBarSection(),
                          Expanded(
                            child: BlocBuilder<CityBloc, CityState>(
                              builder: (context, cityState) {
                                return BlocBuilder<WeatherBloc, WeatherState>(
                                  builder: (context, weatherState) {
                                    return _buildBody(
                                      context,
                                      cityState,
                                      weatherState,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CityState cityState,
    WeatherState weatherState,
  ) {
    if (cityState.status == CityStatus.error &&
        cityState.selectedCity == null) {
      return WeatherErrorView(
        message: cityState.failure?.userMessage ?? '定位失败，请重试',
        onRetry: () => context.read<CityBloc>().add(const CityRelocated()),
      );
    }
    if (cityState.savedCities.isEmpty) {
      return const WeatherLoadingView();
    }

    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        // 只处理 PageView 的水平滚动，忽略天气内容区的垂直滚动。
        if (notification.metrics.axis == Axis.horizontal) {
          _handlePageSettled(cityState);
        }
        return false;
      },
      child: PageView.builder(
        controller: _pageController,
        itemCount: cityState.savedCities.length,
        itemBuilder: (context, index) {
          final city = cityState.savedCities[index];
          final weatherBloc = context.read<WeatherBloc>();
          final inMemoryWeather = weatherBloc.weatherFor(city);
          if (inMemoryWeather != null) {
            return WeatherContent(
              weather: inMemoryWeather,
              onRefresh: () => _refresh(context),
            );
          }
          final isSelected = city.cacheKey == cityState.selectedCity?.cacheKey;
          if (!isSelected) return const WeatherLoadingView();
          return _buildSelectedPage(context, cityState, weatherState);
        },
      ),
    );
  }

  Widget _buildSelectedPage(
    BuildContext context,
    CityState cityState,
    WeatherState weatherState,
  ) {
    final selectedCity = cityState.selectedCity;
    // 城市刚切换、天气 bloc 还没处理新请求时，不展示上一个城市的天气。
    if (selectedCity == null ||
        weatherState.city?.cacheKey != selectedCity.cacheKey) {
      return const WeatherLoadingView();
    }
    final weather = weatherState.weather;
    if (weather == null) {
      if (weatherState.status == WeatherStatus.error) {
        final city = cityState.selectedCity;
        return WeatherErrorView(
          message: weatherState.failure?.userMessage ?? '天气加载失败',
          onRetry: city == null
              ? null
              : () => context.read<WeatherBloc>().add(WeatherRequested(city)),
        );
      }
      return const WeatherLoadingView();
    }
    return WeatherContent(weather: weather, onRefresh: () => _refresh(context));
  }

  Future<void> _refresh(BuildContext context) async {
    final weatherBloc = context.read<WeatherBloc>();
    final future = weatherBloc.stream
        .firstWhere(
          (state) =>
              state.status == WeatherStatus.ready ||
              state.status == WeatherStatus.error,
        )
        .timeout(
          const Duration(seconds: 25),
          onTimeout: () => weatherBloc.state,
        );
    weatherBloc.add(const WeatherRefreshed());
    await future;
  }
}

/// 背景只关心"选中城市 + 天气类型"，避免每次天气状态变化都重建粒子动画。
class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CityBloc, CityState>(
      buildWhen: (previous, current) =>
          previous.selectedCity?.cacheKey != current.selectedCity?.cacheKey,
      builder: (context, cityState) {
        return BlocBuilder<WeatherBloc, WeatherState>(
          buildWhen: (previous, current) =>
              previous.weather?.realtime?.skycon !=
                  current.weather?.realtime?.skycon ||
              previous.city?.cacheKey != current.city?.cacheKey,
          builder: (context, weatherState) {
            final selectedCity = cityState.selectedCity;
            final matches =
                selectedCity != null &&
                weatherState.city?.cacheKey == selectedCity.cacheKey;
            final weather = matches ? weatherState.weather : null;
            if (weather == null) return const _StaticGradientBackground();
            return WeatherMainBg(
              weatherType: WeatherStyle.typeOf(weather.realtime?.skycon),
            );
          },
        );
      },
    );
  }
}

/// 顶栏只订阅 CityBloc，天气状态变化不会导致顶栏重建。
class _HomeTopBarSection extends StatelessWidget {
  const _HomeTopBarSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CityBloc, CityState>(
      builder: (context, cityState) {
        return HomeTopBar(
          cityName: cityState.selectedCity?.displayedName ?? '正在定位…',
          cities: cityState.savedCities,
          selectedIndex: cityState.selectedIndex,
          onLocate: () => context.read<CityBloc>().add(const CityRelocated()),
          onOpenCities: () =>
              Navigator.of(context).pushNamed(CityRoutes.cityManager),
          onCitySelected: (city) =>
              context.read<CityBloc>().add(CitySelected(city)),
        );
      },
    );
  }
}

class _StaticGradientBackground extends StatelessWidget {
  const _StaticGradientBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF0071D1), Color(0xFF6DA6E4)],
        ),
      ),
    );
  }
}
