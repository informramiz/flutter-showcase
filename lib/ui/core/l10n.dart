import 'package:flutter/widgets.dart';
import 'package:flutter_showcase/l10n/app_localizations.dart';

export 'package:flutter_showcase/l10n/app_localizations.dart';

/// Shorthand for the generated localizations: `context.l10n.appTitle`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
