// 模块：SharedPreferences 键值存储（core/storage）
// 作用：KeyValueStore 的真实实现，用于持久化登录态、主题偏好等小数据。
// 依赖：shared_preferences（SharedPreferencesAsync，2.5.x 起推荐的异步 API）。
// 替换建议：
//   - 令牌等敏感数据 → flutter_secure_storage（Keychain / Keystore）
//   - 大数据 / 结构化数据 → sqflite / drift / hive
//   以上都只需实现同一个 KeyValueStore 接口，业务代码无需改动。
// 注意：SharedPreferences 只能存基础类型，这里统一按 String 存取，
//       结构化数据由调用方自行 JSON 序列化（见 WeatherLocalDataSource）。

import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

/// 基于 SharedPreferences 的键值存储。
class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> delete(String key) => _preferences.remove(key);

  @override
  Future<void> clear() => _preferences.clear();
}
