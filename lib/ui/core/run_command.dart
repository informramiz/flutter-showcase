import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_showcase/ui/core/failure_message.dart';
import 'package:flutter_showcase/ui/core/l10n.dart';

/// Runs a view-model [command] from an event handler and shows a snack bar
/// when it fails, instead of letting the error escape as an unhandled
/// asynchronous exception.
void runCommand(BuildContext context, Future<void> Function() command) {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  unawaited(() async {
    try {
      await command();
    } on Object catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(describeError(error, l10n))));
    }
  }());
}
