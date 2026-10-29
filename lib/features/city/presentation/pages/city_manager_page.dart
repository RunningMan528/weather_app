/// 模块：城市管理页（city/presentation/pages）
/// 作用：展示已保存城市、切换/删除城市、进入搜索页。
/// 依赖：flutter_bloc + 本模块 bloc/组件/领域实体。
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/city_weather_summary.dart';
import '../bloc/city_bloc.dart';
import '../bloc/city_event.dart';
import '../bloc/city_manager_bloc.dart';
import '../bloc/city_manager_event.dart';
import '../bloc/city_manager_state.dart';
import '../bloc/city_state.dart';
import '../city_routes.dart';
import '../widgets/city_weather_card.dart';
import '../../../../app/widgets/swipe_delete_card.dart';

class CityManagerPage extends StatefulWidget {
  const CityManagerPage({super.key});

  @override
  State<CityManagerPage> createState() => _CityManagerPageState();
}

class _CityManagerPageState extends State<CityManagerPage> {
  @override
  void initState() {
    super.initState();
    // BlocListener 不会为初始状态触发，首次进入时主动请求一次摘要。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestSummaries();
    });
  }

  void _requestSummaries() {
    final cities = context.read<CityBloc>().state.savedCities;
    context.read<CityManagerBloc>().add(CityManagerSummariesRequested(cities));
  }

  bool _citiesChanged(CityState previous, CityState current) {
    if (previous.savedCities.length != current.savedCities.length) return true;
    for (var i = 0; i < previous.savedCities.length; i++) {
      if (previous.savedCities[i].cacheKey != current.savedCities[i].cacheKey ||
          previous.savedCities[i].displayedName !=
              current.savedCities[i].displayedName) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: BlocListener<CityBloc, CityState>(
          listenWhen: _citiesChanged,
          listener: (_, _) => _requestSummaries(),
          child: Column(
            children: [
              const _ManagerAppBar(),
              _ManagerSearchBar(
                onTap: () =>
                    Navigator.of(context).pushNamed(CityRoutes.citySearch),
              ),
              Expanded(
                child: BlocBuilder<CityBloc, CityState>(
                  builder: (context, cityState) {
                    return BlocBuilder<CityManagerBloc, CityManagerState>(
                      builder: (context, managerState) {
                        return _buildContent(context, cityState, managerState);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CityState cityState,
    CityManagerState managerState,
  ) {
    final cities = cityState.savedCities;
    if (cities.isEmpty) {
      return const Center(
        child: Text('暂无城市', style: TextStyle(color: Colors.black54)),
      );
    }
    final summaries = <String, CityWeatherSummary>{
      for (final summary in managerState.summaries)
        summary.city.cacheKey: summary,
    };
    return Column(
      children: [
        if (managerState.isLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: cities.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final city = cities[index];
              final card = CityWeatherCard(
                summary:
                    summaries[city.cacheKey] ?? CityWeatherSummary(city: city),
                isSelected: city.cacheKey == cityState.selectedCity?.cacheKey,
                onTap: () {
                  context.read<CityBloc>().add(CitySelected(city));
                  Navigator.of(context).pop();
                },
              );
              if (city.isLocated) {
                return KeyedSubtree(
                  key: ValueKey<String>(city.cacheKey),
                  child: card,
                );
              }
              return SwipeDeleteCard(
                key: ValueKey<String>('swipe-${city.cacheKey}'),
                onDelete: () => context.read<CityBloc>().add(CityRemoved(city)),
                child: card,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ManagerAppBar extends StatelessWidget {
  const _ManagerAppBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kToolbarHeight,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF333333),
                size: 20,
              ),
            ),
          ),
          const Center(
            child: Text(
              '城市管理',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerSearchBar extends StatelessWidget {
  const _ManagerSearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        margin: const EdgeInsets.fromLTRB(12, 2, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F1F3),
          borderRadius: BorderRadius.circular(100),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              '搜索城市天气',
              style: TextStyle(fontSize: 15, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }
}
