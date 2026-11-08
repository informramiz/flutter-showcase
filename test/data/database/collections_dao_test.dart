import 'package:flutter_showcase/data/database/app_database.dart';
import 'package:flutter_showcase/data/repositories/collections_repository_impl.dart';
import 'package:flutter_showcase/domain/models/meal_collection.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/database.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

void main() {
  late AppDatabase database;
  late CollectionsRepositoryImpl repository;

  setUp(() {
    database = memoryDatabase();
    repository = CollectionsRepositoryImpl(
      database.collectionsDao,
      () => testNow,
    );
  });

  Future<List<MealCollection>> collections() =>
      repository.watchCollections().first;

  test('collections are sorted ignoring case, with meal counts', () async {
    final dinners = await repository.create('  dinners ');
    await repository.create('Breakfast');
    await repository.setMembership(dinners, pasta, included: true);
    await repository.setMembership(dinners, curry, included: true);

    expect(await collections(), [
      const MealCollection(id: 2, name: 'Breakfast'),
      MealCollection(id: dinners, name: 'dinners', mealCount: 2),
    ]);
  });

  test('a meal can be in many collections, once each', () async {
    final a = await repository.create('A');
    final b = await repository.create('B');
    await repository.setMembership(a, pasta, included: true);
    await repository.setMembership(a, pasta, included: true);
    await repository.setMembership(b, pasta, included: true);

    expect(await repository.watchCollectionIdsFor(pasta.id).first, {a, b});
    expect(await repository.watchMeals(a).first, [
      pasta.copyWith(area: null),
    ]);
  });

  test('removing a meal leaves the collection and other meals', () async {
    final id = await repository.create('A');
    await repository.setMembership(id, pasta, included: true);
    await repository.setMembership(id, curry, included: true);

    await repository.setMembership(id, pasta, included: false);

    expect((await repository.watchMeals(id).first).map((m) => m.id), ['2']);
  });

  test('rename trims and deleting cascades to memberships', () async {
    final id = await repository.create('A');
    await repository.setMembership(id, pasta, included: true);

    await repository.rename(id, ' Quick ');
    expect((await collections()).single.name, 'Quick');

    await repository.delete(id);
    expect(await collections(), isEmpty);
    expect(await repository.watchCollectionIdsFor(pasta.id).first, isEmpty);
    expect(await database.select(database.collectionMeals).get(), isEmpty);
  });

  test('exact duplicate names are rejected by the database', () async {
    await repository.create('A');
    expect(() => repository.create('A'), throwsA(anything));
  });
}
