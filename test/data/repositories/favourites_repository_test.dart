import 'package:flutter_showcase/data/database/meal_cache_dao.dart';
import 'package:flutter_showcase/data/repositories/favourites_repository_impl.dart';
import 'package:flutter_showcase/data/services/preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/database.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

void main() {
  late MealCacheDao dao;

  setUp(() => dao = memoryDatabase().mealCacheDao);

  Future<(FavouritesRepositoryImpl, PreferencesService)> make([
    Map<String, Object> prefs = const {},
  ]) async {
    final service = PreferencesService(await fakePrefs(prefs));
    return (FavouritesRepositoryImpl(dao, service, () => testNow), service);
  }

  Future<List<String>> ids(FavouritesRepositoryImpl repo) async => [
    for (final m in await repo.watchFavourites().first) m.id,
  ];

  test('toggle adds newest first, then removes', () async {
    final (repo, _) = await make();
    var tick = 0;
    final timed = FavouritesRepositoryImpl(
      dao,
      PreferencesService(await fakePrefs()),
      () => testNow.add(Duration(seconds: tick++)),
    );

    await timed.toggle(pasta);
    await timed.toggle(curry);
    expect(await ids(repo), ['2', '1']);

    await timed.toggle(pasta);
    expect(await ids(repo), ['2']);
  });

  test('imports favourites saved by the old version, once', () async {
    final (repo, prefs) = await make({
      legacyFavouritesKey:
          '[{"id":"2","name":"Chicken Curry","thumbnailUrl":"u"}, '
          '{"id":"1","name":"Pasta","thumbnailUrl":"u","category":"Pasta"}]',
    });

    await repo.importLegacy();

    expect(await ids(repo), ['2', '1']);
    expect(prefs.getString(legacyFavouritesKey), isNull);
    await repo.importLegacy();
    expect(await ids(repo), ['2', '1']);
  });

  test('corrupt legacy data is dropped without crashing', () async {
    final (repo, prefs) = await make({legacyFavouritesKey: 'not json'});

    await repo.importLegacy();

    expect(await ids(repo), isEmpty);
    expect(prefs.getString(legacyFavouritesKey), isNull);
  });
}
