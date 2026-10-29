/// 模块：首页顶部栏（shell/presentation/widgets）
/// 作用：组合城市名、城市切换圆点、重新定位与城市管理入口。
/// 依赖：Flutter + city/domain 的 City 实体（shell 组合层允许）。
library;

import 'package:flutter/material.dart';

import '../../../features/city/domain/entities/city.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.cityName,
    required this.cities,
    required this.selectedIndex,
    required this.onLocate,
    required this.onOpenCities,
    required this.onCitySelected,
  });

  final String cityName;
  final List<City> cities;
  final int selectedIndex;
  final VoidCallback onLocate;
  final VoidCallback onOpenCities;
  final ValueChanged<City> onCitySelected;

  List<City> _visibleCities() {
    const maxDots = 8;
    if (cities.length <= maxDots) return cities;
    final result = cities.take(maxDots - 1).toList(growable: true);
    final selected = cities[selectedIndex.clamp(0, cities.length - 1)];
    if (!result.any((city) => city.cacheKey == selected.cacheKey)) {
      result.add(selected);
    }
    return result;
  }

  Widget _buildIndicator() {
    if (cities.length <= 1) {
      return Container(
        width: 18,
        height: 2,
        decoration: BoxDecoration(
          color: Colors.white54,
          borderRadius: BorderRadius.circular(1),
        ),
      );
    }
    final visible = _visibleCities();
    final selected = cities[selectedIndex.clamp(0, cities.length - 1)];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final city in visible)
          GestureDetector(
            onTap: () => onCitySelected(city),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Icon(
                city.isLocated ? Icons.location_on : Icons.circle,
                size: city.isLocated
                    ? 10
                    : (city.cacheKey == selected.cacheKey ? 7 : 5),
                color: city.cacheKey == selected.cacheKey
                    ? Colors.white
                    : Colors.white54,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kToolbarHeight,
      child: Row(
        children: [
          IconButton(
            onPressed: onOpenCities,
            tooltip: '城市管理',
            icon: const Icon(Icons.add, color: Colors.white),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cityName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                _buildIndicator(),
              ],
            ),
          ),
          IconButton(
            onPressed: onLocate,
            tooltip: '重新定位',
            icon: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
