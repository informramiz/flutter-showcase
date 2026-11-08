import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/models/plan.dart';

/// The weekly meal plan and which shopping-list items are ticked off,
/// stored on the device.
abstract interface class PlannerRepository {
  /// The plan ordered by day, slot and position. Emits on listen and after
  /// every change.
  Stream<List<PlannedMeal>> watchPlan();

  /// Appends [meal] to [day]/[slot]. Returns the new entry's id.
  Future<int> add(Meal meal, PlanDay day, MealSlot slot);

  /// Moves an entry to [index] within [day]/[slot].
  Future<void> move(int entryId, PlanDay day, MealSlot slot, int index);

  Future<void> remove(int entryId);

  Future<void> setReminder(int entryId, {required bool enabled});

  /// Keys of the shopping-list items the user has ticked off.
  Stream<Set<String>> watchCheckedKeys();

  Future<void> setChecked(String key, {required bool checked});

  Future<void> uncheckAll();
}
