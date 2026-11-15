import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/l10n/app_localizations.dart';

/// Human-readable text for any error, exhaustive over [AppFailure].
String describeError(Object error, AppLocalizations l10n) =>
    error is AppFailure ? _describeFailure(error, l10n) : l10n.errorUnknown;

// No wildcard: adding an AppFailure subtype is a compile error until handled.
String _describeFailure(AppFailure failure, AppLocalizations l10n) =>
    switch (failure) {
      NetworkFailure() => l10n.errorNetwork,
      ServerFailure(statusCode: final int code) => l10n.errorServerCode(code),
      ServerFailure() => l10n.errorServer,
      ParseFailure() => l10n.errorParse,
      NotFoundFailure() => l10n.notFound,
      UnknownFailure() => l10n.errorUnknown,
    };
