import 'package:flutter_showcase/data/database/planner_dao.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_showcase/domain/repositories/planner_repository.dart';

class PlannerRepositoryImpl implements PlannerRepository {
  PlannerRepositoryImpl(this._dao);

  final PlannerDao _dao;

  @override
  Stream<List<PlannedMeal>> watchPlan() => _dao.watchPlan();

  @override
  Future<int> add(Meal meal, PlanDay day, MealSlot slot) =>
      _dao.addEntry(meal, day, slot);

  @override
  Future<void> move(int entryId, PlanDay day, MealSlot slot, int index) =>
      _dao.moveEntry(entryId, day, slot, index);

  @override
  Future<void> remove(int entryId) => _dao.removeEntry(entryId);

  @override
  Future<void> setReminder(int entryId, {required bool enabled}) =>
      _dao.setReminder(entryId, enabled: enabled);

  @override
  Stream<Set<String>> watchCheckedKeys() => _dao.watchCheckedKeys();

  @override
  Future<void> setChecked(String key, {required bool checked}) =>
      _dao.setChecked(key, checked: checked);

  @override
  Future<void> uncheckAll() => _dao.clearChecks();
}
