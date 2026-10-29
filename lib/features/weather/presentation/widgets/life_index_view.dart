/// 模块：生活指数（presentation/widgets）
/// 作用：展示今日紫外线/洗车/穿衣/舒适/感冒指数，点击查看多日详情。
/// 依赖：Flutter + 本模块实体/样式。
/// 说明：台风入口保留为提示，不引入 url_launcher/语音播报。
library;

import 'package:flutter/material.dart';

import '../../domain/entities/weather.dart';
import '../utils/time_formatter.dart';
import '../utils/weather_style.dart';
import '../../../../app/widgets/blur_card.dart';

class LifeIndexView extends StatelessWidget {
  const LifeIndexView({super.key, required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(weather.daily?.lifeIndex);
    if (items.isEmpty) return const SizedBox.shrink();

    return BlurCard(
      color: _cardColor(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _LifeIndexItem(
              item: item,
              onTap: () => _onTap(context, item),
            );
          },
        ),
      ),
    );
  }

  List<_LifeIndexDisplay> _buildItems(DailyLifeIndex? lifeIndex) {
    if (lifeIndex == null) return const <_LifeIndexDisplay>[];
    final result = <_LifeIndexDisplay>[];

    void add(List<LifeIndexEntry> entries, LifeIndexType type) {
      if (entries.isEmpty) return;
      final today = _todayEntry(entries);
      result.add(
        _LifeIndexDisplay(
          type: type,
          desc: today?.desc ?? entries.first.desc ?? '',
          entries: entries,
        ),
      );
    }

    add(lifeIndex.ultraviolet, LifeIndexType.ultraviolet);
    add(lifeIndex.carWashing, LifeIndexType.carWashing);
    add(lifeIndex.dressing, LifeIndexType.dressing);
    add(lifeIndex.comfort, LifeIndexType.comfort);
    add(lifeIndex.coldRisk, LifeIndexType.coldRisk);
    if (result.isEmpty) return const <_LifeIndexDisplay>[];
    result.add(
      const _LifeIndexDisplay(
        type: LifeIndexType.typhoon,
        desc: '详情',
        entries: <LifeIndexEntry>[],
      ),
    );
    return result;
  }

  LifeIndexEntry? _todayEntry(List<LifeIndexEntry> entries) {
    final now = DateTime.now();
    for (final entry in entries) {
      final date = TimeFormatter.tryParse(entry.date);
      if (date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return entry;
      }
    }
    return null;
  }

  Color _cardColor() {
    final colors = WeatherStyle.colors(
      WeatherStyle.typeOf(weather.realtime?.skycon),
    );
    return colors.first.withValues(alpha: 0.22);
  }

  void _onTap(BuildContext context, _LifeIndexDisplay item) {
    if (item.type == LifeIndexType.typhoon) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('台风路径请前往官方渠道查看')));
      return;
    }
    final colors = WeatherStyle.colors(
      WeatherStyle.typeOf(weather.realtime?.skycon),
    );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => BlurCard(
        color: colors.first.withValues(alpha: 0.72),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.4,
          child: _LifeIndexSheet(item: item),
        ),
      ),
    );
  }
}

class _LifeIndexDisplay {
  const _LifeIndexDisplay({
    required this.type,
    required this.desc,
    required this.entries,
  });

  final LifeIndexType type;
  final String desc;
  final List<LifeIndexEntry> entries;
}

class _LifeIndexItem extends StatelessWidget {
  const _LifeIndexItem({required this.item, required this.onTap});

  final _LifeIndexDisplay item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            WeatherStyle.lifeIndexIcon(item.type),
            width: 28,
            height: 28,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            item.desc,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 5),
          Text(
            WeatherStyle.lifeIndexLabel(item.type),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LifeIndexSheet extends StatelessWidget {
  const _LifeIndexSheet({required this.item});

  final _LifeIndexDisplay item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 54,
          child: Center(
            child: Text(
              WeatherStyle.lifeIndexLabel(item.type),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemCount: item.entries.length,
            itemBuilder: (context, index) {
              final entry = item.entries[index];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    WeatherStyle.lifeIndexIcon(item.type),
                    width: 28,
                    height: 28,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    entry.desc ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    TimeFormatter.weatherDayLabel(entry.date),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
