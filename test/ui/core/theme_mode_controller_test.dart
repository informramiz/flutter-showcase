import 'package:flutter/material.dart';
import 'package:flutter_showcase/ui/core/theme/theme_mode_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/harness.dart';

void main() {
  group('themeModeControllerProvider', () {
    test('defaults to system and ignores unknown stored values', () async {
      final container = await makeContainer(
        MockMealRepository(),
        prefs: {themeModeKey: 'neon'},
      );
      expect(container.read(themeModeControllerProvider), ThemeMode.system);
    });

    test('toggle flips against the current brightness and persists', () async {
      final container = await makeContainer(MockMealRepository());
      final controller = container.read(themeModeControllerProvider.notifier);

      await controller.toggle(Brightness.light);
      expect(container.read(themeModeControllerProvider), ThemeMode.dark);

      await controller.toggle(Brightness.dark);
      expect(container.read(themeModeControllerProvider), ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(themeModeKey), 'light');
    });
  });
}
