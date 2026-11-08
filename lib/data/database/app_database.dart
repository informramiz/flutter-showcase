import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_showcase/data/database/meal_cache_dao.dart';
import 'package:flutter_showcase/data/database/planner_dao.dart';
import 'package:flutter_showcase/data/database/tables.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// The app's local SQLite database: the single source of truth that every
/// repository reads from. Opened on native through `sqlite3_flutter_libs` and
/// on the web through `sqlite3.wasm` plus a drift worker.
@DriftDatabase(
  tables: [
    CachedMeals,
    MealIngredients,
    CachedQueries,
    QueryResults,
    Categories,
    Favourites,
    PlanEntries,
    ShoppingChecks,
  ],
  daos: [MealCacheDao, PlannerDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _open() => driftDatabase(
    name: 'meal_finder',
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationSupportDirectory,
    ),
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
