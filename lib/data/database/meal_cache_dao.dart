import 'package:drift/drift.dart';
import 'package:flutter_showcase/data/database/app_database.dart';
import 'package:flutter_showcase/data/database/tables.dart';
import 'package:flutter_showcase/domain/models/meal.dart';

part 'meal_cache_dao.g.dart';

/// A cached value and when it was fetched from the network.
typedef CacheHit<T> = ({T data, DateTime fetchedAt});

/// Upper bound for offline searches, which scan the whole local library.
const localSearchLimit = 50;

/// Reads and writes the cached copy of TheMealDB plus the user's favourites.
@DriftAccessor(
  tables: [
    CachedMeals,
    MealIngredients,
    CachedQueries,
    QueryResults,
    Categories,
    Favourites,
  ],
)
class MealCacheDao extends DatabaseAccessor<AppDatabase>
    with _$MealCacheDaoMixin {
  MealCacheDao(super.attachedDatabase);

  // List queries -------------------------------------------------------

  Future<CacheHit<List<Meal>>?> mealsForQuery(String key) async {
    final fetchedAt = await _fetchedAt(key);
    if (fetchedAt == null) return null;
    final query =
        select(queryResults).join([
            innerJoin(
              cachedMeals,
              cachedMeals.id.equalsExp(queryResults.mealId),
            ),
          ])
          ..where(queryResults.queryKey.equals(key))
          ..orderBy([OrderingTerm.asc(queryResults.position)]);
    final rows = await query.get();
    return (
      data: [for (final r in rows) _summary(r.readTable(cachedMeals))],
      fetchedAt: fetchedAt,
    );
  }

  /// Replaces the stored result of [key] with [meals].
  Future<void> saveQuery(String key, List<Meal> meals, DateTime fetchedAt) =>
      transaction(() async {
        for (final meal in meals) {
          await _upsertSummary(meal);
        }
        await (delete(
          queryResults,
        )..where((r) => r.queryKey.equals(key))).go();
        await _markFetched(key, fetchedAt);
        await batch((b) {
          b.insertAll(queryResults, [
            for (final (i, m) in meals.indexed)
              QueryResultsCompanion.insert(
                queryKey: key,
                position: i,
                mealId: m.id,
              ),
          ]);
        });
      });

  // Categories ---------------------------------------------------------

  Future<CacheHit<List<String>>?> categoryNames() async {
    final fetchedAt = await _fetchedAt(categoriesKey);
    if (fetchedAt == null) return null;
    final rows = await (select(
      categories,
    )..orderBy([(c) => OrderingTerm.asc(c.position)])).get();
    return (data: [for (final r in rows) r.name], fetchedAt: fetchedAt);
  }

  Future<void> saveCategories(List<String> names, DateTime fetchedAt) =>
      transaction(() async {
        await delete(categories).go();
        await batch((b) {
          b.insertAll(categories, [
            for (final (i, name) in names.indexed)
              CategoriesCompanion.insert(name: name, position: i),
          ]);
        });
        await _markFetched(categoriesKey, fetchedAt);
      });

  // Meal detail --------------------------------------------------------

  /// The full recipe of [id], if it has ever been fetched.
  Future<CacheHit<Meal>?> mealDetail(String id) async {
    final query = select(cachedMeals)
      ..where((m) => m.id.equals(id) & m.detailFetchedAt.isNotNull());
    final row = await query.getSingleOrNull();
    final fetchedAt = row?.detailFetchedAt;
    if (row == null || fetchedAt == null) return null;
    return (data: await _withIngredients(row), fetchedAt: fetchedAt);
  }

  Future<void> saveMealDetail(Meal meal, DateTime fetchedAt) =>
      transaction(() async {
        await into(cachedMeals).insertOnConflictUpdate(
          CachedMealsCompanion.insert(
            id: meal.id,
            name: meal.name,
            thumbnailUrl: meal.thumbnailUrl,
            category: Value(meal.category),
            area: Value(meal.area),
            instructions: Value(meal.instructions),
            tags: Value(meal.tags.join(',')),
            detailFetchedAt: Value(fetchedAt),
          ),
        );
        await (delete(
          mealIngredients,
        )..where((i) => i.mealId.equals(meal.id))).go();
        await batch((b) {
          b.insertAll(mealIngredients, [
            for (final (i, ingredient) in meal.ingredients.indexed)
              MealIngredientsCompanion.insert(
                mealId: meal.id,
                position: i,
                name: ingredient.name,
                measure: ingredient.measure,
              ),
          ]);
        });
      });

  /// Stores [meal]'s summary so other tables can reference it, without
  /// overwriting a cached recipe.
  Future<void> upsertSummary(Meal meal) => _upsertSummary(meal);

  // Offline fallbacks --------------------------------------------------

  /// Meals in the local library whose name contains [query].
  Future<List<Meal>> searchLocal(String query) async {
    final rows =
        await (select(cachedMeals)
              ..where((m) => m.name.like('%${query.trim()}%'))
              ..orderBy([(m) => OrderingTerm.asc(m.name)])
              ..limit(localSearchLimit))
            .get();
    return rows.map(_summary).toList();
  }

  Future<List<Meal>> mealsInCategory(String category) async {
    final rows =
        await (select(cachedMeals)
              ..where((m) => m.category.equals(category))
              ..orderBy([(m) => OrderingTerm.asc(m.name)]))
            .get();
    return rows.map(_summary).toList();
  }

  // Favourites ---------------------------------------------------------

  /// Favourite meals, newest first, re-emitted on every change.
  Stream<List<Meal>> watchFavourites() {
    final query = select(favourites).join([
      innerJoin(cachedMeals, cachedMeals.id.equalsExp(favourites.mealId)),
    ])..orderBy([OrderingTerm.desc(favourites.addedAt)]);
    return query.watch().map(
      (rows) => [for (final r in rows) _summary(r.readTable(cachedMeals))],
    );
  }

  Future<void> toggleFavourite(Meal meal, DateTime now) =>
      transaction(() async {
        final removed = await (delete(
          favourites,
        )..where((f) => f.mealId.equals(meal.id))).go();
        if (removed > 0) return;
        await _upsertSummary(meal);
        await into(
          favourites,
        ).insert(FavouritesCompanion.insert(mealId: meal.id, addedAt: now));
      });

  /// Adds [meal] as a favourite unless it already is one.
  Future<void> addFavourite(Meal meal, DateTime addedAt) =>
      transaction(() async {
        await _upsertSummary(meal);
        await into(favourites).insert(
          FavouritesCompanion.insert(mealId: meal.id, addedAt: addedAt),
          mode: InsertMode.insertOrIgnore,
        );
      });

  // Helpers ------------------------------------------------------------

  Future<DateTime?> _fetchedAt(String key) async {
    final row = await (select(
      cachedQueries,
    )..where((q) => q.queryKey.equals(key))).getSingleOrNull();
    return row?.fetchedAt;
  }

  Future<void> _markFetched(String key, DateTime fetchedAt) =>
      into(
        cachedQueries,
      ).insertOnConflictUpdate(
        CachedQueriesCompanion.insert(queryKey: key, fetchedAt: fetchedAt),
      );

  Future<void> _upsertSummary(Meal meal) => into(cachedMeals).insert(
    CachedMealsCompanion.insert(
      id: meal.id,
      name: meal.name,
      thumbnailUrl: meal.thumbnailUrl,
      category: Value(meal.category),
    ),
    onConflict: DoUpdate(
      (_) => CachedMealsCompanion(
        name: Value(meal.name),
        thumbnailUrl: Value(meal.thumbnailUrl),
        // List endpoints sometimes omit the category; keep the known one.
        category: meal.category == null
            ? const Value.absent()
            : Value(meal.category),
      ),
    ),
  );

  Future<Meal> _withIngredients(CachedMealRow row) async {
    final ingredients =
        await (select(mealIngredients)
              ..where((i) => i.mealId.equals(row.id))
              ..orderBy([(i) => OrderingTerm.asc(i.position)]))
            .get();
    return _summary(row).copyWith(
      area: row.area,
      instructions: row.instructions,
      tags: row.tags.isEmpty ? const [] : row.tags.split(','),
      ingredients: [
        for (final i in ingredients)
          Ingredient(name: i.name, measure: i.measure),
      ],
    );
  }

  static Meal _summary(CachedMealRow row) => Meal(
    id: row.id,
    name: row.name,
    thumbnailUrl: row.thumbnailUrl,
    category: row.category,
  );
}

/// Cache key of the category list.
const categoriesKey = 'categories';

String searchKey(String query) => 'search:${query.trim().toLowerCase()}';

String categoryKey(String category) => 'category:$category';
