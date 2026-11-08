import 'package:drift/drift.dart';
import 'package:flutter_showcase/data/database/app_database.dart';
import 'package:flutter_showcase/data/database/meal_cache_dao.dart';
import 'package:flutter_showcase/data/database/tables.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/models/meal_collection.dart';

part 'collections_dao.g.dart';

/// Reads and writes user collections and which meals they hold.
@DriftAccessor(tables: [Collections, CollectionMeals, CachedMeals])
class CollectionsDao extends DatabaseAccessor<AppDatabase>
    with _$CollectionsDaoMixin {
  CollectionsDao(super.attachedDatabase);

  /// Collections A to Z (ignoring case), each with its meal count.
  Stream<List<MealCollection>> watchCollections() {
    final count = collectionMeals.mealId.count();
    final query =
        select(collections).join([
            leftOuterJoin(
              collectionMeals,
              collectionMeals.collectionId.equalsExp(collections.id),
              useColumns: false,
            ),
          ])
          ..addColumns([count])
          ..groupBy([collections.id])
          ..orderBy([
            OrderingTerm.asc(collections.name.collate(Collate.noCase)),
          ]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          MealCollection(
            id: r.readTable(collections).id,
            name: r.readTable(collections).name,
            mealCount: r.read(count) ?? 0,
          ),
      ],
    );
  }

  /// Meals in collection [collectionId], most recently added first.
  Stream<List<Meal>> watchMeals(int collectionId) {
    final query =
        select(collectionMeals).join([
            innerJoin(
              cachedMeals,
              cachedMeals.id.equalsExp(collectionMeals.mealId),
            ),
          ])
          ..where(collectionMeals.collectionId.equals(collectionId))
          ..orderBy([OrderingTerm.desc(collectionMeals.addedAt)]);
    return query.watch().map(
      (rows) => [
        for (final r in rows) MealCacheDao.summaryOf(r.readTable(cachedMeals)),
      ],
    );
  }

  /// Ids of the collections that contain meal [mealId].
  Stream<Set<int>> watchCollectionIdsFor(String mealId) {
    final query = selectOnly(collectionMeals)
      ..addColumns([collectionMeals.collectionId])
      ..where(collectionMeals.mealId.equals(mealId));
    return query.watch().map(
      (rows) => {for (final r in rows) r.read(collectionMeals.collectionId)!},
    );
  }

  Future<int> createCollection(String name, DateTime now) => into(
    collections,
  ).insert(CollectionsCompanion.insert(name: name, createdAt: now));

  Future<void> renameCollection(int id, String name) =>
      (update(collections)..where((c) => c.id.equals(id))).write(
        CollectionsCompanion(name: Value(name)),
      );

  /// Deletes the collection; its memberships go with it (ON DELETE CASCADE).
  Future<void> deleteCollection(int id) =>
      (delete(collections)..where((c) => c.id.equals(id))).go();

  /// Adds [meal] to the collection unless it is already there.
  Future<void> addMeal(int collectionId, Meal meal, DateTime now) =>
      transaction(() async {
        await attachedDatabase.mealCacheDao.upsertSummary(meal);
        await into(collectionMeals).insert(
          CollectionMealsCompanion.insert(
            collectionId: collectionId,
            mealId: meal.id,
            addedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      });

  Future<void> removeMeal(int collectionId, String mealId) =>
      (delete(collectionMeals)..where(
            (m) =>
                m.collectionId.equals(collectionId) & m.mealId.equals(mealId),
          ))
          .go();
}
