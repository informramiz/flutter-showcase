import 'dart:convert';

import 'package:flutter_showcase/data/repositories/favourites_repository_impl.dart';
import 'package:flutter_showcase/data/services/preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

Future<PreferencesService> _service([
  Map<String, Object> values = const {},
]) async => PreferencesService(await fakePrefs(values));

void main() {
  test('starts empty and survives corrupt data', () async {
    expect(FavouritesRepositoryImpl(await _service()).favourites, isEmpty);
    final corrupt = await _service({favouritesKey: 'not json'});
    expect(FavouritesRepositoryImpl(corrupt).favourites, isEmpty);
  });

  test('toggle adds newest first, removes, and emits every change', () async {
    final repo = FavouritesRepositoryImpl(await _service());
    addTearDown(repo.dispose);
    final emitted = <List<String>>[];
    repo.changes.listen((items) => emitted.add([for (final m in items) m.id]));

    await repo.toggle(pasta);
    await repo.toggle(curry);
    await repo.toggle(pasta);

    expect(emitted, [
      ['1'],
      ['2', '1'],
      ['2'],
    ]);
    expect(repo.favourites.map((m) => m.id), ['2']);
  });

  test('persists only the summary fields and restores them', () async {
    final prefs = await _service();
    final repo = FavouritesRepositoryImpl(prefs);
    addTearDown(repo.dispose);
    await repo.toggle(pasta);

    final stored = jsonDecode(prefs.getString(favouritesKey)!) as List;
    expect(stored.single, {
      'id': '1',
      'name': pasta.name,
      'thumbnailUrl': pasta.thumbnailUrl,
      'category': 'Pasta',
    });

    final restored = FavouritesRepositoryImpl(prefs);
    addTearDown(restored.dispose);
    expect(restored.favourites.single.name, pasta.name);
  });
}
