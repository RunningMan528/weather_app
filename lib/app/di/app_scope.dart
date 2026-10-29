// 模块：依赖作用域（app/di）
// 作用：把 ServiceLocator 挂到 Widget 树上，让任意子页面都能按类型取依赖。
// 依赖：Flutter Widgets + ServiceLocator。
// 与 Provider 的关系：本类等价于 Provider 的 ProviderScope/InheritedWidget 机制，
//   换成 provider / riverpod 时，这里就是唯一需要替换的“注入入口”。
// 使用约定：优先构造器注入（页面显式声明依赖，可测试性最好）；
//   只有在“页面层级很深、逐层透传成本过高”时才用 AppScope.locate(context)。

import 'package:flutter/widgets.dart';

import 'service_locator.dart';

/// 依赖作用域。
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.locator, required super.child});

  /// 全局依赖容器。
  final ServiceLocator locator;

  /// 读取容器。
  static ServiceLocator of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, '未找到 AppScope，请确认它包裹在 MaterialApp 外层');
    return scope!.locator;
  }

  /// 直接解析依赖的快捷方式。
  static T locate<T extends Object>(BuildContext context) =>
      of(context).get<T>();

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.locator != locator;
}
