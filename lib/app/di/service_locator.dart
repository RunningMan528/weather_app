// 模块：依赖容器（app/di）
// 作用：集中注册与解析依赖，让业务代码只依赖抽象、不关心谁创建、何时创建。
// 依赖：纯 Dart（不依赖 Flutter，可单测）。
// 设计说明：这是一个“够用且可读”的实现，刻意不引入第三方包：
//   - registerSingleton    立即创建的单例（无状态服务、数据源）
//   - registerLazySingleton 首次使用时创建的单例（VM、仓库）
//   - registerFactory      每次解析都新建（页面级对象）
//   替换成本：迁移到 get_it / Riverpod 时，只需改 dependency_module 与本文件，
//   业务层代码（domain/presentation）完全不用动。
// 生命周期：dispose() 按注册的逆序释放资源（关闭连接、控制器），避免内存泄漏。

import 'dart:async';

/// 极简依赖容器。
class ServiceLocator {
  final Map<Type, Object> _singletons = <Type, Object>{};
  final Map<Type, FutureOr<Object> Function()> _lazyFactories =
      <Type, FutureOr<Object> Function()>{};
  final Map<Type, Object Function()> _factories = <Type, Object Function()>{};

  /// 释放回调：容器销毁时按注册逆序执行。
  final List<FutureOr<void> Function()> _disposers =
      <FutureOr<void> Function()>[];

  /// 注册一个已经创建好的单例。
  void registerSingleton<T extends Object>(T instance) {
    _singletons[T] = instance;
  }

  /// 注册懒加载单例：首次 [get] 时创建并缓存。
  void registerLazySingleton<T extends Object>(T Function() factory) {
    _lazyFactories[T] = factory;
  }

  /// 注册工厂：每次 [get] 都返回新实例。
  void registerFactory<T extends Object>(T Function() factory) {
    _factories[T] = factory;
  }

  /// 注册释放回调（顺序与注册相反）。
  void registerDisposer(FutureOr<void> Function() disposer) {
    _disposers.add(disposer);
  }

  /// 解析依赖；未注册时抛出清晰的错误，便于启动期发现配置遗漏。
  T get<T extends Object>() {
    final cached = _singletons[T];
    if (cached is T) return cached;

    final factory = _factories[T];
    if (factory != null) return factory() as T;

    final lazy = _lazyFactories[T];
    if (lazy != null) {
      final created = lazy();
      // 懒加载工厂允许返回 Future，这里由调用方通过 [getAsync] 处理同步场景，
      // Demo 中所有懒加载注册都是同步构造，因此直接断言为 T。
      if (created is T) {
        _singletons[T] = created;
        return created;
      }
    }

    throw StateError('依赖未注册: $T。请在 app/di/dependency_module.dart 中注册。');
  }

  /// 安全解析：未注册返回 null，适合可选依赖。
  T? maybeGet<T extends Object>() {
    try {
      return get<T>();
    } on StateError {
      return null;
    }
  }

  /// 是否已注册。
  bool isRegistered<T extends Object>() =>
      _singletons.containsKey(T) ||
      _lazyFactories.containsKey(T) ||
      _factories.containsKey(T);

  /// 释放全部资源：按注册逆序执行释放回调（先关连接，再关控制器）。
  Future<void> dispose() async {
    for (final disposer in _disposers.reversed) {
      await disposer();
    }
    _disposers.clear();
    _singletons.clear();
    _lazyFactories.clear();
    _factories.clear();
  }
}
