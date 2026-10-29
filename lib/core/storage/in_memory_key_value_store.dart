// 模块：内存键值存储（core/storage）
// 作用：KeyValueStore 的演示实现，进程内存保存数据（App 重启后丢失）。
// 依赖：纯 Dart。
// 对应模板：把本类替换为 SharedPreferencesKeyValueStore 即可接入真实持久化，
//           上层 repository 与 usecase 无需任何改动——这正是抽象的意义。

import 'key_value_store.dart';

/// 基于 Map 的键值存储，用于 Demo 与单元测试。
///
/// [writeDelay] 用来模拟真实存储的异步耗时，让 UI 的“正在恢复登录态”可见。
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore({this.writeDelay = Duration.zero});

  final Duration writeDelay;
  final Map<String, String> _memory = <String, String>{};

  /// 只读快照，便于测试断言与调试。
  Map<String, String> get snapshot => Map.unmodifiable(_memory);

  @override
  Future<String?> read(String key) async => _memory[key];

  @override
  Future<void> write(String key, String value) async {
    if (writeDelay > Duration.zero) await Future<void>.delayed(writeDelay);
    _memory[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _memory.remove(key);
  }

  @override
  Future<void> clear() async {
    _memory.clear();
  }
}
