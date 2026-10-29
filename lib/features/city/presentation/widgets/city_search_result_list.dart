/// 模块：城市搜索结果列表（presentation/widgets）
/// 作用：搜索结果以蓝色渐变卡片展示，已添加城市显示"已添加"。
/// 依赖：Flutter + 本模块实体。
library;

import 'package:flutter/material.dart';

import '../../domain/entities/city.dart';

class CitySearchResultList extends StatelessWidget {
  const CitySearchResultList({
    super.key,
    required this.results,
    required this.savedCities,
    required this.onCityTap,
  });

  final List<CitySearchResult> results;
  final List<City> savedCities;
  final ValueChanged<CitySearchResult> onCityTap;

  bool _isSaved(CitySearchResult result) {
    final city = result.toCity();
    return savedCities.any((item) => item.cacheKey == city.cacheKey);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final result = results[index];
        final added = _isSaved(result);
        return GestureDetector(
          onTap: () => onCityTap(result),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF1E88E5), Color(0xFF64B5F6)],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    result.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (added)
                  const Text(
                    '已添加',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
