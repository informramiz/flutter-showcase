// Schema snapshots in drift_schemas/ and generated/ come from
// `dart run drift_dev make-migrations`; see
// https://drift.simonbinder.eu/migrations/tests/
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_showcase/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  group('every upgrade path produces the expected schema', () {
    const versions = GeneratedHelper.versions;
    for (final (i, from) in versions.indexed) {
      for (final to in versions.skip(i + 1)) {
        test('$from to $to', () async {
          final schema = await verifier.schemaAt(from);
          final db = AppDatabase(schema.newConnection());
          await verifier.migrateAndValidate(db, to);
          await db.close();
        });
      }
    }
  });

  test('v1 to v2 keeps favourites and the plan', () async {
    const meal = v1.CachedMealsData(
      id: '1',
      name: 'Pasta',
      thumbnailUrl: 'https://e.com/1.jpg',
      tags: '',
    );
    const favourite = v1.FavouritesData(mealId: '1', addedAt: 1700000000);
    const entry = v1.PlanEntriesData(
      id: 1,
      mealId: '1',
      day: 0,
      slot: 2,
      position: 0,
      reminderEnabled: 0,
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) => batch
        ..insert(oldDb.cachedMeals, meal)
        ..insert(oldDb.favourites, favourite)
        ..insert(oldDb.planEntries, entry),
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.cachedMeals).get(), [
          const v2.CachedMealsData(
            id: '1',
            name: 'Pasta',
            thumbnailUrl: 'https://e.com/1.jpg',
            tags: '',
          ),
        ]);
        expect(await newDb.select(newDb.favourites).get(), [
          const v2.FavouritesData(mealId: '1', addedAt: 1700000000),
        ]);
        expect(await newDb.select(newDb.planEntries).get(), hasLength(1));
        expect(await newDb.select(newDb.collections).get(), isEmpty);
      },
    );
  });
}
