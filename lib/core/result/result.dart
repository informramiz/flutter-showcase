import 'package:flutter_showcase/core/result/failure.dart';

/// Outcome of an operation that can fail, without throwing.
sealed class Result<T> {
  const Result();

  /// Runs [body] and wraps its value, or the [AppFailure] it throws.
  static Future<Result<T>> guard<T>(Future<T> Function() body) async {
    try {
      return Success(await body());
    } on AppFailure catch (failure) {
      return Err(failure);
    }
  }

  /// Returns the value or throws the failure.
  ///
  /// Used at the boundary with Riverpod, where `AsyncValue` carries the error.
  T getOrThrow() => switch (this) {
    Success<T>(:final value) => value,
    Err<T>(:final failure) => throw failure,
  };
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final AppFailure failure;
}
