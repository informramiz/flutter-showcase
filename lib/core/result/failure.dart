/// Everything that can go wrong when talking to the API, as a closed set.
///
/// Being `sealed` means every `switch` over a failure is checked for
/// exhaustiveness by the compiler.
sealed class AppFailure implements Exception {
  const AppFailure();
}

/// No connection, DNS failure or timeout.
final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

/// The server answered with a non-2xx status.
final class ServerFailure extends AppFailure {
  const ServerFailure(this.statusCode);

  final int? statusCode;
}

/// The response arrived but did not have the expected shape.
final class ParseFailure extends AppFailure {
  const ParseFailure();
}

/// The requested resource does not exist.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure();
}

/// Anything else.
final class UnknownFailure extends AppFailure {
  const UnknownFailure();
}
