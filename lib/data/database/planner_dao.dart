import 'package:drift/drift.dart';
import 'package:flutter_showcase/data/database/app_database.dart';
import 'package:flutter_showcase/data/database/tables.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/models/plan.dart';

part 'planner_dao.g.dart';

/// Reads and writes the weekly plan and the shopping list's ticks.
///
/// Within one day and slot, entries keep a dense `position` (0, 1, 2…);
/// every write that changes membership renumbers the lists it touches.
@DriftAccessor(
  tables: [PlanEntries, ShoppingChecks, CachedMeals, MealIngredients],
)
class PlannerDao extends DatabaseAccessor<AppDatabase> with _$PlannerDaoMixin {
  PlannerDao(super.attachedDatabase);

  // Plan ---------------------------------------------------------------

  /// The plan ordered by day, slot and position, with each meal's cached
  /// ingredients. Re-emits when entries, meals or ingredients change, so a
  /// recipe cached after it was planned shows up in the shopping list.
  Stream<List<PlannedMeal>> watchPlan() {
    final query =
        select(planEntries).join([
          innerJoin(cachedMeals, cachedMeals.id.equalsExp(planEntries.mealId)),
          leftOuterJoin(
            mealIngredients,
            mealIngredients.mealId.equalsExp(planEntries.mealId),
          ),
        ])..orderBy([
          OrderingTerm.asc(planEntries.day),
          OrderingTerm.asc(planEntries.slot),
          OrderingTerm.asc(planEntries.position),
          OrderingTerm.asc(mealIngredients.position),
        ]);
    return query.watch().map(_group);
  }

  /// Appends [meal] to the end of [day]/[slot].
  Future<int> addEntry(Meal meal, PlanDay day, MealSlot slot) =>
      transaction(() async {
        await attachedDatabase.mealCacheDao.upsertSummary(meal);
        final position = (await _entriesIn(day, slot)).length;
        return into(planEntries).insert(
          PlanEntriesCompanion.insert(
            mealId: meal.id,
            day: day,
            slot: slot,
            position: position,
          ),
        );
      });

  /// Moves entry [id] to [index] within [day]/[slot] (which may be the list
  /// it is already in). [index] is clamped to the target list.
  Future<void> moveEntry(int id, PlanDay day, MealSlot slot, int index) =>
      transaction(() async {
        final entry = await _entry(id);
        if (entry == null) return;
        final target = [
          for (final e in await _entriesIn(day, slot))
            if (e.id != id) e.id,
        ];
        target.insert(index.clamp(0, target.length), id);
        await (update(planEntries)..where((e) => e.id.equals(id))).write(
          PlanEntriesCompanion(day: Value(day), slot: Value(slot)),
        );
        await _renumber(target);
        if (entry.day != day || entry.slot != slot) {
          await _renumberList(entry.day, entry.slot);
        }
      });

  Future<void> removeEntry(int id) => transaction(() async {
    final entry = await _entry(id);
    if (entry == null) return;
    await (delete(planEntries)..where((e) => e.id.equals(id))).go();
    await _renumberList(entry.day, entry.slot);
  });

  Future<void> setReminder(int id, {required bool enabled}) =>
      (update(planEntries)..where((e) => e.id.equals(id))).write(
        PlanEntriesCompanion(reminderEnabled: Value(enabled)),
      );

  // Shopping checks ----------------------------------------------------

  Stream<Set<String>> watchCheckedKeys() => select(shoppingChecks).watch().map(
    (rows) => {
      for (final r in rows) r.itemKey,
    },
  );

  Future<void> setChecked(String key, {required bool checked}) => checked
      ? into(shoppingChecks).insert(
          ShoppingChecksCompanion.insert(itemKey: key),
          mode: InsertMode.insertOrIgnore,
        )
      : (delete(shoppingChecks)..where((c) => c.itemKey.equals(key))).go();

  Future<void> clearChecks() => delete(shoppingChecks).go();

  // Helpers ------------------------------------------------------------

  Future<PlanEntryRow?> _entry(int id) =>
      (select(planEntries)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<List<PlanEntryRow>> _entriesIn(PlanDay day, MealSlot slot) =>
      (select(planEntries)
            ..where(
              (e) => e.day.equalsValue(day) & e.slot.equalsValue(slot),
            )
            ..orderBy([(e) => OrderingTerm.asc(e.position)]))
          .get();

  Future<void> _renumberList(PlanDay day, MealSlot slot) async =>
      _renumber([for (final e in await _entriesIn(day, slot)) e.id]);

  Future<void> _renumber(List<int> ids) => batch((b) {
    for (final (position, id) in ids.indexed) {
      b.update(
        planEntries,
        PlanEntriesCompanion(position: Value(position)),
        where: (e) => e.id.equals(id),
      );
    }
  });

  List<PlannedMeal> _group(List<TypedResult> rows) {
    final entries = <int, PlanEntryRow>{};
    final meals = <int, CachedMealRow>{};
    final ingredients = <int, List<Ingredient>>{};
    for (final row in rows) {
      final entry = row.readTable(planEntries);
      entries[entry.id] = entry;
      meals[entry.id] = row.readTable(cachedMeals);
      final list = ingredients.putIfAbsent(entry.id, () => []);
      if (row.readTableOrNull(mealIngredients) case final i?) {
        list.add(Ingredient(name: i.name, measure: i.measure));
      }
    }
    return [
      for (final MapEntry(key: id, value: entry) in entries.entries)
        PlannedMeal(
          entryId: id,
          day: entry.day,
          slot: entry.slot,
          position: entry.position,
          reminderEnabled: entry.reminderEnabled,
          meal: Meal(
            id: meals[id]!.id,
            name: meals[id]!.name,
            thumbnailUrl: meals[id]!.thumbnailUrl,
            category: meals[id]!.category,
            ingredients: ingredients[id]!,
          ),
        ),
    ];
  }
}
