import 'dart:async';

import 'package:flutter_showcase/data/services/cook_reminder_service.dart';
import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_showcase/domain/repositories/planner_repository.dart';
import 'package:flutter_showcase/domain/services/plan_schedule.dart';
import 'package:flutter_showcase/router.dart';
import 'package:flutter_showcase/ui/planner/planner_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'planner_view_model.g.dart';

/// The localized text of an entry's cook reminder, supplied by the UI.
typedef ReminderText = ({String title, String body});

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

  /// Moves [entry] to the end of [day]/[slot]. An enabled reminder moves
  /// with it.
  Future<void> moveTo(
    PlannedMeal entry,
    PlanDay day,
    MealSlot slot, {
    required ReminderText reminder,
  }) async {
    if (entry.day == day && entry.slot == slot) return;
    await _repository.move(entry.entryId, day, slot, _countIn(day, slot));
    if (entry.reminderEnabled) {
      await _schedule(entry.copyWith(day: day, slot: slot), reminder);
    }
  }

  Future<void> remove(PlannedMeal entry) async {
    await _repository.remove(entry.entryId);
    if (entry.reminderEnabled) await _reminders.cancel(entry.entryId);
  }

  /// Whether cook reminders can be offered on this platform.
  bool get remindersSupported => _reminders.isSupported;

  /// Turns [entry]'s weekly cook reminder on or off. Returns `false` when
  /// the user refused notification permission, and nothing changed.
  Future<bool> setReminder(
    PlannedMeal entry, {
    required bool enabled,
    required ReminderText text,
  }) async {
    if (enabled) {
      if (!await _reminders.requestPermission()) return false;
      await _schedule(entry, text);
    } else {
      await _reminders.cancel(entry.entryId);
    }
    await _repository.setReminder(entry.entryId, enabled: enabled);
    return true;
  }

  Future<void> _schedule(PlannedMeal entry, ReminderText text) =>
      _reminders.scheduleWeekly(
        id: entry.entryId,
        at: nextCookReminder(entry.day, entry.slot, ref.read(clockProvider)()),
        title: text.title,
        body: text.body,
        route: Routes.meal(entry.meal.id),
      );

  int _countIn(PlanDay day, MealSlot slot) => (state.plan.value ?? const [])
      .where((e) => e.day == day && e.slot == slot)
      .length;

  PlannerRepository get _repository => ref.read(plannerRepositoryProvider);

  CookReminderService get _reminders => ref.read(cookReminderServiceProvider);
}
