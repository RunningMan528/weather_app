/// 模块：城市搜索页（city/presentation/pages）
/// 作用：热门城市 + 关键词搜索结果，选择后加入城市管理并返回。
/// 依赖：flutter_bloc + 本模块 bloc/组件/领域实体。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/city.dart';
import '../bloc/city_bloc.dart';
import '../bloc/city_event.dart';
import '../bloc/city_search_bloc.dart';
import '../bloc/city_search_event.dart';
import '../bloc/city_search_state.dart';
import '../bloc/city_state.dart';
import '../widgets/city_search_bar.dart';
import '../widgets/city_search_result_list.dart';
import '../widgets/hot_cities_view.dart';

class CitySearchPage extends StatefulWidget {
  const CitySearchPage({super.key});

  @override
  State<CitySearchPage> createState() => _CitySearchPageState();
}

class _CitySearchPageState extends State<CitySearchPage> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<CitySearchBloc>().add(CitySearchKeywordChanged(value));
    });
  }

  void _onSubmitted(String value) {
    _debounce?.cancel();
    context.read<CitySearchBloc>().add(CitySearchKeywordChanged(value));
  }

  void _addOrSelect(City city) {
    final cityBloc = context.read<CityBloc>();
    final exists = cityBloc.state.savedCities.any(
      (item) => item.cacheKey == city.cacheKey,
    );
    cityBloc.add(exists ? CitySelected(city) : CityAdded(city));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CitySearchBar(
              onChanged: _onChanged,
              onSubmitted: _onSubmitted,
              onCancel: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: BlocBuilder<CityBloc, CityState>(
                builder: (context, cityState) {
                  return BlocBuilder<CitySearchBloc, CitySearchState>(
                    builder: (context, searchState) {
                      if (searchState.keyword.isEmpty) {
                        return HotCitiesView(
                          savedCities: cityState.savedCities,
                          onCityTap: _addOrSelect,
                        );
                      }
                      return _buildSearchContent(cityState, searchState);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContent(CityState cityState, CitySearchState searchState) {
    switch (searchState.status) {
      case CitySearchStatus.idle:
      case CitySearchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case CitySearchStatus.empty:
        return const Center(
          child: Text('未找到城市', style: TextStyle(color: Colors.black54)),
        );
      case CitySearchStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                searchState.failure?.userMessage ?? '搜索失败',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.read<CitySearchBloc>().add(
                  CitySearchKeywordChanged(searchState.keyword),
                ),
                child: const Text('重试'),
              ),
            ],
          ),
        );
      case CitySearchStatus.ready:
        return CitySearchResultList(
          results: searchState.results,
          savedCities: cityState.savedCities,
          onCityTap: (result) => _addOrSelect(result.toCity()),
        );
    }
  }
}
