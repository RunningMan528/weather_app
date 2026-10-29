// 模块：HTTP 客户端契约（core/network）
// 作用：定义 data 层可用的网络能力，屏蔽 dio 等具体实现。
// 依赖：纯 Dart + core 的 Result/Failure。
// 设计要点：
//   1) 只暴露"语义化方法 + Result"，不向 data 层泄漏 dio 类型（换实现不用改业务代码）；
//   2) 契约里没有 Response/Request 对象：data 层只关心"拿到 JSON 或拿到 Failure"；
//   3) 取消、重试、鉴权、日志都在实现层（拦截器）解决。

import '../error/result.dart';

/// HTTP 客户端契约。
abstract class ApiClient {
  /// GET，返回对象（JSON Object）。
  Future<Result<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? query,
  });

  /// GET，返回数组（JSON Array of Object）。
  Future<Result<List<Map<String, dynamic>>>> getList(
    String path, {
    Map<String, dynamic>? query,
  });

  /// POST，返回对象。
  Future<Result<Map<String, dynamic>>> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  });

  /// PUT，返回对象。
  Future<Result<Map<String, dynamic>>> put(String path, {Object? body});

  /// DELETE，不关心响应体。
  Future<Result<Unit>> delete(String path, {Object? body});
}
