import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/l10n/app_localizations.dart';

/// Human-readable text for any error, exhaustive over [AppFailure].
String describeError(Object error, AppLocalizations l10n) => switch (error) {
  NetworkFailure() => l10n.errorNetwork,
  ServerFailure(statusCode: final int code) => l10n.errorServerCode(code),
  ServerFailure() => l10n.errorServer,
  ParseFailure() => l10n.errorParse,
  NotFoundFailure() => l10n.notFound,
  _ => l10n.errorUnknown,
};
