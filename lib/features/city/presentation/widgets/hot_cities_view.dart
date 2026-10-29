/// 模块：热门城市（presentation/widgets）
/// 作用：搜索页初始状态的热门城市胶囊按钮。
/// 依赖：Flutter + 本模块实体/热门城市数据。
library;

import 'package:flutter/material.dart';

import '../../domain/entities/city.dart';
import '../utils/hot_cities.dart';

class HotCitiesView extends StatelessWidget {
  const HotCitiesView({
    super.key,
    required this.savedCities,
    required this.onCityTap,
  });

  final List<City> savedCities;
  final ValueChanged<City> onCityTap;

  bool _isSaved(City city) =>
      savedCities.any((item) => item.cacheKey == city.cacheKey);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text(
          '热门城市',
          style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: kHotCities
              .map((hot) {
                final city = hot.toCity();
                final added = _isSaved(city);
                return ActionChip(
                  elevation: 0,
                  backgroundColor: const Color(0xFFF2F3F5),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  label: Text(
                    hot.name,
                    style: TextStyle(
                      color: added
                          ? const Color(0xFF1E88E5)
                          : const Color(0xFF333333),
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () => onCityTap(city),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}
