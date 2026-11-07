import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/core/strings.dart';

/// Human-readable text for any error, exhaustive over [AppFailure].
String describeError(Object error) => switch (error) {
  NetworkFailure() => Strings.errorNetwork,
  ServerFailure(:final statusCode) => Strings.errorServer(statusCode),
  ParseFailure() => Strings.errorParse,
  NotFoundFailure() => Strings.notFound,
  _ => Strings.errorUnknown,
};
