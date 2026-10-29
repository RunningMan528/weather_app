// 模块：dio 实现（core/network）
// 作用：把 dio 的响应/异常统一翻译成 Result + Failure，data 层只看到"成功数据或领域错误"。
// 依赖：dio + core 的 Result/Failure/ApiEnvelope。
// 错误映射约定（与后端约定保持一致，便于跨端对齐）：
//   HTTP 200 + code != 0  → ServerFailure(code = 业务码)
//   400 / 422             → ValidationFailure
//   401 / 403             → AuthFailure（UI 可据此引导重新登录）
//   404                   → NotFoundFailure
//   5xx / 其他            → ServerFailure
//   连接失败 / 超时        → NetworkFailure / TimeoutFailure（可重试）

import 'package:dio/dio.dart';

import '../error/failure.dart';
import '../error/result.dart';
import 'api_client.dart';
import 'api_response.dart';

/// 基于 dio 的 HTTP 客户端。
class DioApiClient implements ApiClient {
  DioApiClient(this._dio);

  final Dio _dio;

  @override
  Future<Result<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? query,
  }) {
    return _send(
      () => _dio.get<dynamic>(path, queryParameters: query),
      ApiEnvelope.asMap,
    );
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) {
    return _send(
      () => _dio.get<dynamic>(path, queryParameters: query),
      ApiEnvelope.asList,
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) {
    return _send(
      () => _dio.post<dynamic>(path, data: body, queryParameters: query),
      ApiEnvelope.asMap,
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> put(String path, {Object? body}) {
    return _send(() => _dio.put<dynamic>(path, data: body), ApiEnvelope.asMap);
  }

  @override
  Future<Result<Unit>> delete(String path, {Object? body}) {
    return _send(
      () => _dio.delete<dynamic>(path, data: body),
      (_) => Unit.value,
    );
  }

  /// 统一发送流程：请求 → 拆信封 → 解码；任何异常都翻译成 Failure。
  Future<Result<T>> _send<T>(
    Future<Response<dynamic>> Function() send,
    T Function(dynamic data) decode,
  ) {
    return Result.guard(() async {
      final response = await send();
      return decode(ApiEnvelope.unwrap(response.data));
    }, onError: _mapError);
  }

  /// 异常 → 领域 Failure。
  Failure _mapError(Object error, StackTrace stack) {
    if (error is ApiBusinessException) {
      return ServerFailure(
        message: error.message,
        code: error.code,
        cause: error,
      );
    }
    if (error is DioException) return _mapDioException(error);
    if (error is FormatException) {
      return UnknownFailure(message: '数据解析失败：${error.message}', cause: error);
    }
    return UnknownFailure(message: error.toString(), cause: error);
  }

  /// 异常类型 → 领域 Failure 的显式映射。
  ///
  /// 这里刻意**保持穷尽、不加 `_` 兜底分支**，原因值得记一笔：
  /// `dio` 的约束是 `^5.9.2`（允许小版本升级），上游一新增枚举值（例如 5.11 的
  /// `DioExceptionType.transformTimeout`），这个 switch 就会变成非穷尽 —— 那是
  /// **编译期错误**，release 构建会在 `:app:compileFlutterBuildRelease` 阶段失败，
  /// 而 fastlane 只给出一句 "Exit status of command 'flutter build apk --release …'
  /// was 1 instead of 0"，从这行字看不出任何线索（2026-10 真实踩过）。
  ///
  /// 防护措施（同批修复）：
  ///   1) `pubspec.lock` 已入库 → CI 与本地解析出**同一个** dio 版本，不再悄悄漂移；
  ///   2) Fastlane 的质量门禁改为在项目根目录执行 `flutter analyze`
  ///      （见 `fastlane/Fastfile` 的 `run_quality_gate`）—— 以前它只在 `fastlane/`
  ///      目录里分析，等于空操作，所以这个错误才一路漏到编译阶段。
  /// 于是升级依赖后若出现 `non_exhaustive_switch_expression`，会在 analyze 阶段
  /// 直接指出文件、行号和缺失的枚举值，20 秒就能定位。
  /// 若确实希望"上游新增类型也不阻断构建"，再加 `_ => NetworkFailure(...)` 兜底即可。
  Failure _mapDioException(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => TimeoutFailure(cause: error),
      DioExceptionType.connectionError => NetworkFailure(cause: error),
      DioExceptionType.badCertificate => const NetworkFailure(
        message: 'HTTPS 证书校验失败',
      ),
      DioExceptionType.cancel => const NetworkFailure(message: '请求已取消'),
      DioExceptionType.badResponse => _mapStatusCode(error),
      DioExceptionType.unknown => NetworkFailure(
        message: '网络异常，请稍后重试',
        cause: error,
      ),
      DioExceptionType.transformTimeout => TimeoutFailure(cause: error),
    };
  }

  /// 按 HTTP 状态码分类，并保留服务端返回的业务码与文案。
  Failure _mapStatusCode(DioException error) {
    final status = error.response?.statusCode ?? 0;
    final body = error.response?.data;
    final message = _fieldOf(body, 'message');
    final code = _fieldOf(body, 'code') ?? '$status';

    return switch (status) {
      400 ||
      422 => ValidationFailure(message ?? '请求参数不合法', code: code, cause: error),
      401 || 403 => AuthFailure(
        message: message ?? '登录状态已失效',
        code: code,
        cause: error,
      ),
      404 => NotFoundFailure(
        message: message ?? '请求的资源不存在',
        code: code,
        cause: error,
      ),
      _ => ServerFailure(
        message: message ?? '服务暂时不可用（$status）',
        code: code,
        cause: error,
      ),
    };
  }

  /// 安全读取响应体字段（响应体可能不是 Map，或字段缺失）。
  String? _fieldOf(dynamic body, String key) {
    if (body is Map && body[key] != null) return '${body[key]}';
    return null;
  }
}
