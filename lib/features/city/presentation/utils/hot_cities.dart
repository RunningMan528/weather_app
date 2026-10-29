/// 模块：热门城市（presentation/utils）
/// 作用：搜索页在未输入关键词时展示的固定城市列表。
/// 依赖：本模块领域实体。
library;

import '../../domain/entities/city.dart';

class HotCity {
  const HotCity(this.name, this.longitude, this.latitude);

  final String name;
  final double longitude;
  final double latitude;

  City toCity() => City(
    latitude: latitude,
    longitude: longitude,
    displayedName: name,
    isLocated: false,
  );
}

const List<HotCity> kHotCities = <HotCity>[
  HotCity('北京市', 116.405285, 39.904989),
  HotCity('上海市', 121.472644, 31.231706),
  HotCity('广州市', 113.280637, 23.125178),
  HotCity('深圳市', 114.085947, 22.547),
  HotCity('珠海市', 113.553986, 22.224979),
  HotCity('佛山市', 113.122717, 23.028762),
  HotCity('南京市', 118.767413, 32.041544),
  HotCity('苏州市', 120.619585, 31.299379),
  HotCity('厦门市', 118.11022, 24.490474),
  HotCity('南宁市', 108.320004, 22.82402),
  HotCity('成都市', 104.065735, 30.659462),
  HotCity('长沙市', 112.982279, 28.19409),
  HotCity('杭州市', 120.153576, 30.287459),
  HotCity('武汉市', 114.298572, 30.584355),
  HotCity('青岛市', 120.355173, 36.082982),
  HotCity('西安市', 108.940175, 34.341568),
  HotCity('太原市', 112.549248, 37.857014),
  HotCity('石家庄市', 114.502461, 38.045474),
  HotCity('重庆市', 106.504962, 29.533155),
  HotCity('天津市', 117.190182, 39.125596),
];
