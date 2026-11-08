import 'package:flutter_showcase/data/database/meal_cache_dao.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/database.dart';
import '../../helpers/fixtures.dart';

void main() {
  late MealCacheDao dao;
  final at = DateTime(2026, 11, 8, 9);

  setUp(() => dao = memoryDatabase().mealCacheDao);

  test('an unknown query is a cache miss', () async {
    expect(await dao.mealsForQuery(searchKey('x')), isNull);
    expect(await dao.categoryNames(), isNull);
    expect(await dao.mealDetail('1'), isNull);
  });

  test('saveQuery stores the list in order and replaces it on save', () async {
    final key = searchKey(' Pasta ');
    await dao.saveQuery(key, [curry, pasta], at);

    final hit = await dao.mealsForQuery(key);
    expect(hit!.fetchedAt, at);
    expect(hit.data.map((m) => m.id), ['2', '1']);

    final later = at.add(const Duration(hours: 2));
    await dao.saveQuery(key, [pasta], later);
    final replaced = await dao.mealsForQuery(key);
    expect(replaced!.data.map((m) => m.id), ['1']);
    expect(replaced.fetchedAt, later);
  });

  test('search keys ignore case and surrounding spaces', () {
    expect(searchKey(' PASTA '), searchKey('pasta'));
    expect(categoryKey('Beef'), 'category:Beef');
  });

  test('categories keep their order', () async {
    await dao.saveCategories(['Beef', 'Pasta'], at);
    await dao.saveCategories(['Vegan', 'Beef'], at);

    final hit = await dao.categoryNames();
    expect(hit!.data, ['Vegan', 'Beef']);
  });

  test('a meal detail round-trips with ingredients and tags', () async {
    await dao.saveMealDetail(pastaDetail, at);

    final hit = await dao.mealDetail('1');
    expect(hit!.data, pastaDetail);
    expect(hit.fetchedAt, at);
  });

  test('a list refresh does not wipe a cached recipe', () async {
    await dao.saveMealDetail(pastaDetail, at);
    await dao.saveQuery(
      categoryKey('Pasta'),
      [pasta.copyWith(name: 'Renamed', category: null)],
      at,
    );

    final detail = (await dao.mealDetail('1'))!.data;
    expect(detail.name, 'Renamed');
    expect(detail.category, 'Pasta');
    expect(detail.ingredients, hasLength(2));
  });

  test('offline search and category lookups read the library', () async {
    await dao.saveQuery(searchKey(''), [pasta, curry], at);

    expect((await dao.searchLocal('CURRY')).single.id, '2');
    expect(await dao.searchLocal('zzz'), isEmpty);
    expect((await dao.mealsInCategory('Pasta')).single.id, '1');
  });

  test('favourites are newest first and toggle on and off', () async {
    final emitted = <List<String>>[];
    final subscription = dao.watchFavourites().listen(
      (items) => emitted.add([for (final m in items) m.id]),
    );
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await dao.toggleFavourite(pasta, at);
    await pumpEventQueue();
    await dao.toggleFavourite(curry, at.add(const Duration(minutes: 1)));
    await pumpEventQueue();
    await dao.toggleFavourite(pasta, at);
    await pumpEventQueue();

    expect(emitted.first, isEmpty);
    expect(
      emitted,
      containsAllInOrder([
        ['1'],
        ['2', '1'],
        ['2'],
      ]),
    );
  });

  test('addFavourite is idempotent', () async {
    await dao.addFavourite(pasta, at);
    await dao.addFavourite(pasta, at.add(const Duration(days: 1)));

    final favourites = await dao.watchFavourites().first;
    expect(favourites, [
      const Meal(
        id: '1',
        name: 'Spaghetti Bolognese',
        thumbnailUrl: 'https://example.com/pasta.jpg',
        category: 'Pasta',
      ),
    ]);
  });
}
