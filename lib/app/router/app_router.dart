/// 模块：路由表（app/router）
/// 作用：集中装配页面与页面级 bloc；城市/天气应用级 bloc 由 app 根组件提供。
/// 依赖：flutter_bloc + 各 feature 页面/bloc + ServiceLocator。
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/city/presentation/bloc/city_manager_bloc.dart';
import '../../features/city/presentation/bloc/city_search_bloc.dart';
import '../../features/city/presentation/city_routes.dart';
import '../../features/city/presentation/pages/city_manager_page.dart';
import '../../features/city/presentation/pages/city_search_page.dart';
import '../di/service_locator.dart';
import '../../shell/presentation/pages/home_page.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter(this._locator);

  final ServiceLocator _locator;

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
      case null:
        return MaterialPageRoute<void>(
          settings: const RouteSettings(name: AppRoutes.home),
          builder: (_) => const HomePage(),
        );
      case CityRoutes.cityManager:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider<CityManagerBloc>(
            create: (_) => _locator.get<CityManagerBloc>(),
            child: const CityManagerPage(),
          ),
        );
      case CityRoutes.citySearch:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider<CitySearchBloc>(
            create: (_) => _locator.get<CitySearchBloc>(),
            child: const CitySearchPage(),
          ),
        );
      default:
        return null;
    }
  }
}
