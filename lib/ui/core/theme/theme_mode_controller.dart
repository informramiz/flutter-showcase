import 'package:flutter/material.dart';
import 'package:flutter_showcase/di/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_controller.g.dart';

const themeModeKey = 'theme_mode';

/// Follows the system until the user picks one, then remembers the choice.
@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() {
    final stored = ref
        .watch(preferencesServiceProvider)
        .getString(themeModeKey);
    return ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
  }

  Future<void> toggle(Brightness current) async {
    final next = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await ref
        .read(preferencesServiceProvider)
        .setString(themeModeKey, next.name);
  }
}
