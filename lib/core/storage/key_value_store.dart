// 模块：键值存储抽象（core/storage）
// 作用：为“登录态、开关、草稿”这类小数据提供统一读写接口，屏蔽具体实现。
// 依赖：纯 Dart。
// 对应模板：真实项目里由 shared_preferences / flutter_secure_storage / MMKV 实现该接口，
//           本 Demo 用内存实现，保证无网络、无插件即可运行。

/// 键值存储契约：异步读写，失败以异常形式抛出，由 repository 翻译成 Failure。
abstract class KeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  /// 清空全部数据：账号切换、退出登录时调用。
  Future<void> clear();
}
