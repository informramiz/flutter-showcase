import 'package:drift/drift.dart';
import 'package:flutter_showcase/domain/models/plan.dart';

/// Every meal the app has seen. Rows from list endpoints carry only the
/// summary; [detailFetchedAt] is set once the full recipe has been cached.
@DataClassName('CachedMealRow')
class CachedMeals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get thumbnailUrl => text()();
  TextColumn get category => text().nullable()();
  TextColumn get area => text().nullable()();
  TextColumn get instructions => text().nullable()();

  /// Tags joined with commas; they are only ever displayed together.
  TextColumn get tags => text().withDefault(const Constant(''))();
  DateTimeColumn get detailFetchedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MealIngredientRow')
class MealIngredients extends Table {
  TextColumn get mealId =>
      text().references(CachedMeals, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get name => text()();
  TextColumn get measure => text()();

  @override
  Set<Column<Object>> get primaryKey => {mealId, position};
}

/// When each list query (`categories`, `search:<q>`, `category:<c>`) was
/// last fetched from the network.
@DataClassName('CachedQueryRow')
class CachedQueries extends Table {
  TextColumn get queryKey => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {queryKey};
}

/// The ordered meals a cached list query returned.
@DataClassName('QueryResultRow')
class QueryResults extends Table {
  TextColumn get queryKey => text().references(
    CachedQueries,
    #queryKey,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get position => integer()();
  TextColumn get mealId => text().references(CachedMeals, #id)();

  @override
  Set<Column<Object>> get primaryKey => {queryKey, position};
}

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get name => text()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

@DataClassName('FavouriteRow')
class Favourites extends Table {
  TextColumn get mealId => text().references(CachedMeals, #id)();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {mealId};
}

@DataClassName('PlanEntryRow')
class PlanEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mealId => text().references(CachedMeals, #id)();
  IntColumn get day => intEnum<PlanDay>()();
  IntColumn get slot => intEnum<MealSlot>()();
  IntColumn get position => integer()();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();
}

/// Shopping-list items the user ticked off, by normalised ingredient name.
@DataClassName('ShoppingCheckRow')
class ShoppingChecks extends Table {
  TextColumn get itemKey => text()();

  @override
  Set<Column<Object>> get primaryKey => {itemKey};
}

/// A user-named group of meals. Added in schema v2.
@DataClassName('CollectionRow')
class Collections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Which meals are in which collection (many-to-many). Added in schema v2.
@DataClassName('CollectionMealRow')
class CollectionMeals extends Table {
  IntColumn get collectionId =>
      integer().references(Collections, #id, onDelete: KeyAction.cascade)();
  TextColumn get mealId => text().references(CachedMeals, #id)();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {collectionId, mealId};
}
