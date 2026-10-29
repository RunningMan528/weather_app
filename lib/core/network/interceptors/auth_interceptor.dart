// 模块：鉴权拦截器（core/network/interceptors）
// 作用：为请求自动附加 Authorization 头，并在 401 时通知上层（触发登出/刷新）。
// 依赖：dio + TokenProvider + core 工具。
// 扩展点：真实项目常在这里做"刷新令牌合并"——多个请求同时 401 只刷新一次，
//          其余请求等待刷新完成后重放（本 Demo 留出 onUnauthorized 回调作为入口）。

import 'package:dio/dio.dart';

import '../token_provider.dart';

/// 鉴权拦截器。
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenProvider, this.onUnauthorized});

  final TokenProvider tokenProvider;

  /// 收到 401 时的回调：通常用于清空登录态并跳转登录页。
  final void Function()? onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenProvider.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
