// 模块：日志拦截器（core/network/interceptors）
// 作用：打印请求耗时、状态码与响应体（截断 + 脱敏），便于本地联调与线上排障。
// 依赖：dart:developer（Flutter 自带，不引入 print，符合 lint 规范）。
// 安全要求：Authorization / token / 手机号等敏感字段必须脱敏，且响应体只打印前 N 个字符。

import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// 日志拦截器。
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({this.maxBodyLength = 300, this.enabled = true});

  /// 单条日志最多打印的响应体长度。
  final int maxBodyLength;

  final bool enabled;

  static const String _startKey = 'request_start_time';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) return handler.next(options);
    options.extra[_startKey] = DateTime.now().microsecondsSinceEpoch;
    developer.log(
      '→ ${options.method} ${options.uri.path}'
      '${_maskQuery(options.uri.query)}',
      name: 'api',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!enabled) return handler.next(response);
    developer.log(
      '← ${response.statusCode} ${response.requestOptions.uri.path} '
      '(${_elapsed(response.requestOptions)}ms) ${_truncate(response.data)}',
      name: 'api',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled) return handler.next(err);
    developer.log(
      '✗ ${err.type.name} ${err.requestOptions.uri.path} '
      '(${_elapsed(err.requestOptions)}ms) ${err.message}',
      name: 'api',
      level: 900,
    );
    handler.next(err);
  }

  /// 计算耗时（毫秒）。
  int _elapsed(RequestOptions options) {
    final start = options.extra[_startKey];
    if (start is! int) return 0;
    return ((DateTime.now().microsecondsSinceEpoch - start) / 1000).round();
  }

  /// 截断响应体，避免大 payload 刷屏。
  String _truncate(dynamic data) {
    final text = data?.toString() ?? '';
    return text.length <= maxBodyLength
        ? text
        : '${text.substring(0, maxBodyLength)}…(${text.length})';
  }

  /// 查询串脱敏：只保留参数名，避免把 token、手机号打进日志。
  String _maskQuery(String query) {
    if (query.isEmpty) return '';
    final keys = query.split('&').map((pair) => pair.split('=').first);
    return '?${keys.map((key) => '$key=***').join('&')}';
  }
}
