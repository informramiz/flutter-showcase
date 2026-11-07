import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/core/result/result.dart';

/// Lets a view model publish a repository [Result] as UI state.
extension ResultAsyncValue<T> on Result<T> {
  AsyncValue<T> toAsyncValue() => switch (this) {
    Success<T>(:final value) => AsyncData(value),
    Err<T>(:final failure) => AsyncError(failure, StackTrace.empty),
  };
}
