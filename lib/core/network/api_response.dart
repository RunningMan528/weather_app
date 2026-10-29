// 模块：接口响应信封（core/network）
// 作用：把 { code, message, data } 这种团队通用约定收敛在一处解析。
// 依赖：纯 Dart。
// 约定：code == 0 表示业务成功；非 0 抛出 [ApiBusinessException]，
//       由 DioApiClient 统一翻译成 ServerFailure（带业务码）。

/// 业务异常：HTTP 200 但业务码表示失败。
class ApiBusinessException implements Exception {
  const ApiBusinessException(this.code, this.message, {this.traceId});

  /// 业务错误码（字符串便于跨端对齐，如 'INVALID_CREDENTIALS'）。
  final String code;

  final String message;

  /// 服务端链路追踪 id：排障时用于关联日志。
  final String? traceId;

  @override
  String toString() => 'ApiBusinessException($code, $message)';
}

/// 响应信封解析。
class ApiEnvelope {
  const ApiEnvelope._();

  /// 业务成功码。
  static const int successCode = 0;

  /// 取出业务数据：支持"带信封"和"裸 JSON"两种后端风格。
  static dynamic unwrap(dynamic body) {
    if (body is Map<String, dynamic> && body.containsKey('code')) {
      final code = body['code'];
      final isSuccess = code == successCode || code == '0';
      if (!isSuccess) {
        throw ApiBusinessException(
          '${body['code']}',
          (body['message'] as String?) ?? '业务处理失败',
          traceId: body['traceId'] as String?,
        );
      }
      return body['data'];
    }
    // 兼容不走信封的接口（直接返回对象/数组）。
    return body;
  }

  /// 把任意 JSON 安全地转成 Map。
  static Map<String, dynamic> asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data == null) return <String, dynamic>{};
    throw const FormatException('期望 JSON Object，实际收到其他类型');
  }

  /// 把任意 JSON 安全地转成 List<Map>。
  static List<Map<String, dynamic>> asList(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    if (data == null) return const <Map<String, dynamic>>[];
    throw const FormatException('期望 JSON Array，实际收到其他类型');
  }
}
