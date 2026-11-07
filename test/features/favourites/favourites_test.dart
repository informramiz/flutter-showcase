import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_showcase/core/storage/preferences_provider.dart';
import 'package:flutter_showcase/core/theme/theme_mode_provider.dart';
import 'package:flutter_showcase/features/favourites/data/favourites_repository.dart';
import 'package:flutter_showcase/features/favourites/presentation/favourites_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

void main() {
  group('FavouritesRepository', () {
    test('round-trips the summary fields', () async {
      final repo = FavouritesRepository(await fakePrefs());
      await repo.save([pasta, curry]);

      final loaded = repo.load();

      expect(loaded.map((m) => m.id), ['1', '2']);
      expect(loaded.first.name, pasta.name);
      expect(loaded.first.category, 'Pasta');
    });

    test('starts empty and survives corrupt data', () async {
      expect(FavouritesRepository(await fakePrefs()).load(), isEmpty);
      final corrupt = await fakePrefs({favouritesKey: 'not json'});
      expect(FavouritesRepository(corrupt).load(), isEmpty);
    });
  });

  group('favouritesProvider', () {
    test('toggle adds, removes and persists', () async {
      final container = await makeContainer(MockMealRepository());
      final notifier = container.read(favouritesProvider.notifier);

      await notifier.toggle(pasta);
      await notifier.toggle(curry);
      expect(container.read(favouritesProvider).map((m) => m.id), ['2', '1']);
      expect(container.read(isFavouriteProvider('1')), isTrue);

      await notifier.toggle(pasta);
      expect(container.read(favouritesProvider).map((m) => m.id), ['2']);
      expect(container.read(isFavouriteProvider('1')), isFalse);

      final prefs = container.read(sharedPreferencesProvider);
      final stored = jsonDecode(prefs.getString(favouritesKey)!) as List;
      expect(stored, hasLength(1));
    });

    test('restores favourites saved by a previous run', () async {
      final seed = await fakePrefs();
      await FavouritesRepository(seed).save([pasta]);

      final container = await makeContainer(
        MockMealRepository(),
        prefs: {favouritesKey: seed.getString(favouritesKey)!},
      );

      expect(container.read(favouritesProvider).single.id, '1');
    });
  });

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
