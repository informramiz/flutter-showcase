import 'package:dio/dio.dart';
import 'package:flutter_showcase/core/result/failure.dart';

/// Translates every [DioException] into an [AppFailure] stored in
/// `DioException.error`, so the API client never inspects Dio internals.
class FailureInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: mapFailure(err)));
  }

  static AppFailure mapFailure(DioException err) {
    final existing = err.error;
    if (existing is AppFailure) return existing;
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout ||
      DioExceptionType.connectionError => const NetworkFailure(),
      DioExceptionType.badResponse =>
        err.response?.statusCode == 404
            ? const NotFoundFailure()
            : ServerFailure(err.response?.statusCode),
      DioExceptionType.badCertificate ||
      DioExceptionType.cancel ||
      DioExceptionType.unknown => const UnknownFailure(),
    };
  }
}
