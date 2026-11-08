import 'dart:async';

import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_showcase/domain/repositories/planner_repository.dart';
import 'package:flutter_showcase/ui/planner/planner_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'planner_view_model.g.dart';

/// View model of the weekly Planner. The database is the source of truth;
/// commands write to it and the plan stream brings the change back.
@Riverpod(keepAlive: true)
class PlannerViewModel extends _$PlannerViewModel {
  @override
  PlannerUiState build() {
    final subscription = ref
        .watch(plannerRepositoryProvider)
        .watchPlan()
        .listen(
          (plan) => state = PlannerUiState(plan: AsyncData(plan)),
          onError: (Object error, StackTrace stack) =>
              state = PlannerUiState(plan: AsyncError(error, stack)),
        );
    ref.onDispose(() => unawaited(subscription.cancel()));
    return const PlannerUiState();
  }

  /// Whether [entry] is the last one in its day and slot.
  bool isLastInSlot(PlannedMeal entry) =>
      entry.position == _countIn(entry.day, entry.slot) - 1;

  Future<void> moveUp(PlannedMeal entry) async {
    if (entry.position == 0) return;
    await _repository.move(
      entry.entryId,
      entry.day,
      entry.slot,
      entry.position - 1,
    );
  }

  Future<void> moveDown(PlannedMeal entry) async {
    if (isLastInSlot(entry)) return;
    await _repository.move(
      entry.entryId,
      entry.day,
      entry.slot,
      entry.position + 1,
    );
  }

  /// Moves [entry] to the end of [day]/[slot].
  Future<void> moveTo(PlannedMeal entry, PlanDay day, MealSlot slot) async {
    if (entry.day == day && entry.slot == slot) return;
    await _repository.move(entry.entryId, day, slot, _countIn(day, slot));
  }

  Future<void> remove(PlannedMeal entry) => _repository.remove(entry.entryId);

  int _countIn(PlanDay day, MealSlot slot) => (state.plan.value ?? const [])
      .where((e) => e.day == day && e.slot == slot)
      .length;

  PlannerRepository get _repository => ref.read(plannerRepositoryProvider);
}
