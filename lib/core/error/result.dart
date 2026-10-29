// 模块：结果类型（core/error）
// 作用：用 Result<T> 表达“成功或失败”的返回值，让用例签名显式包含错误分支，
//       代替到处 try/catch 或向上抛异常。
// 依赖：纯 Dart。
// 对应模板：与 sealed Failure 配合使用；data 层负责把异常翻译成 Failure。

import 'failure.dart';

/// 用例返回值：只可能是 [Ok] 或 [Err]。
sealed class Result<T> {
  const Result();

  /// 是否成功。
  bool get isOk => this is Ok<T>;

  /// 是否失败。
  bool get isErr => this is Err<T>;

  /// 成功值，失败时为 null。
  T? get valueOrNull => this is Ok<T> ? (this as Ok<T>).value : null;

  /// 失败对象，成功时为 null。
  Failure? get failureOrNull =>
      this is Err<T> ? (this as Err<T>).failure : null;

  /// 分支处理：UI 与上层用例统一用 when 消费结果，避免强转。
  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) {
    final self = this;
    return switch (self) {
      Ok<T>(:final value) => ok(value),
      Err<T>(:final failure) => err(failure),
    };
  }

  /// 映射成功值，失败原样传递：用于 data → domain 的模型转换。
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Ok<R>(transform(value)),
    Err<T>(:final failure) => Err<R>(failure),
  };

  /// 解析型映射：把"取到的原始数据"转成领域对象，解析异常由 [onError] 兜底。
  ///
  /// 与 [map] 的区别：map 不捕获转换函数抛出的异常，parse 会捕获——
  /// 因此 data 层解析 JSON 时应使用 parse，避免脏数据以异常形式穿透到上层。
  Result<R> parse<R>(
    R Function(T value) transform, {
    Failure Function(Object error, StackTrace stack)? onError,
  }) {
    if (this is Err<T>) return Err<R>((this as Err<T>).failure);
    return Result.guardSync(
      () => transform((this as Ok<T>).value),
      onError: onError,
    );
  }

  /// 失败时回退到默认值，适合“拿不到就用缓存/默认”的场景。
  T getOrElse(T fallback) => valueOrNull ?? fallback;

  /// 把可能抛异常的任务收敛成 [Result]，data 层解析与 IO 的入口。
  ///
  /// [onError] 允许调用方把底层异常翻译成更精确的 Failure。
  static Future<Result<T>> guard<T>(
    Future<T> Function() task, {
    Failure Function(Object error, StackTrace stack)? onError,
  }) async {
    try {
      return Ok<T>(await task());
    } catch (error, stack) {
      return Err<T>(
        onError?.call(error, stack) ??
            UnknownFailure(message: error.toString(), cause: error),
      );
    }
  }

  /// 同步版本的 [guard]，用于本地计算与解析。
  static Result<T> guardSync<T>(
    T Function() task, {
    Failure Function(Object error, StackTrace stack)? onError,
  }) {
    try {
      return Ok<T>(task());
    } catch (error, stack) {
      return Err<T>(
        onError?.call(error, stack) ??
            UnknownFailure(message: error.toString(), cause: error),
      );
    }
  }
}

/// 成功结果。
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  String toString() => 'Ok($value)';
}

/// 失败结果。
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  String toString() => 'Err($failure)';
}

/// 空值占位：让“没有返回值的用例”使用 `Result<Unit>`，避免 void 泛型的写法歧义。
///
/// 例如 LogoutUseCase 返回 `Future<Result<Unit>>`。
final class Unit {
  const Unit._();

  static const Unit value = Unit._();

  @override
  String toString() => 'unit';
}
