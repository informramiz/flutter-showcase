import 'package:dio/dio.dart';
import 'package:flutter_showcase/core/failure_message.dart';
import 'package:flutter_showcase/core/network/failure_interceptor.dart';
import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/core/strings.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dioError(DioExceptionType type, {int? status}) => DioException(
  requestOptions: RequestOptions(),
  type: type,
  response: status == null
      ? null
      : Response(requestOptions: RequestOptions(), statusCode: status),
);

void main() {
  group('Result', () {
    test('guard wraps a value in Success', () async {
      final result = await Result.guard(() async => 42);
      expect(result, isA<Success<int>>());
      expect(result.getOrThrow(), 42);
    });

    test('guard turns an AppFailure into Err', () async {
      final result = await Result.guard<int>(
        () async => throw const NetworkFailure(),
      );
      expect(result, isA<Err<int>>());
      expect(
        () => result.getOrThrow(),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('guard does not swallow programmer errors', () {
      expect(
        Result.guard<int>(() async => throw StateError('bug')),
        throwsStateError,
      );
    });
  });

  group('FailureInterceptor.mapFailure', () {
    test('maps timeouts and connection errors to NetworkFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(
          FailureInterceptor.mapFailure(_dioError(type)),
          isA<NetworkFailure>(),
          reason: '$type',
        );
      }
    });

    test('maps 404 to NotFoundFailure and other statuses to ServerFailure', () {
      final notFound = FailureInterceptor.mapFailure(
        _dioError(DioExceptionType.badResponse, status: 404),
      );
      final server = FailureInterceptor.mapFailure(
        _dioError(DioExceptionType.badResponse, status: 503),
      );
      expect(notFound, isA<NotFoundFailure>());
      expect(
        server,
        isA<ServerFailure>().having((f) => f.statusCode, 'code', 503),
      );
    });

    test('maps cancel, bad certificate and unknown to UnknownFailure', () {
      for (final type in [
        DioExceptionType.cancel,
        DioExceptionType.badCertificate,
        DioExceptionType.unknown,
      ]) {
        expect(
          FailureInterceptor.mapFailure(_dioError(type)),
          isA<UnknownFailure>(),
        );
      }
    });

    test('keeps an AppFailure that is already attached', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        error: const ParseFailure(),
      );
      expect(FailureInterceptor.mapFailure(error), isA<ParseFailure>());
    });
  });

  group('describeError', () {
    test('gives a message per failure', () {
      expect(describeError(const NetworkFailure()), Strings.errorNetwork);
      expect(describeError(const ServerFailure(500)), Strings.errorServer(500));
      expect(
        describeError(const ServerFailure(null)),
        Strings.errorServer(null),
      );
      expect(describeError(const ParseFailure()), Strings.errorParse);
      expect(describeError(const NotFoundFailure()), Strings.notFound);
      expect(describeError(const UnknownFailure()), Strings.errorUnknown);
      expect(describeError(StateError('x')), Strings.errorUnknown);
    });
  });
}
