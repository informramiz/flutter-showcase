import 'package:flutter_showcase/domain/models/plan.dart';

/// When a slot's meal is eaten, and so when its cook reminder fires.
extension MealSlotSchedule on MealSlot {
  /// Hour of day the meal is eaten.
  int get hour => switch (this) {
    MealSlot.breakfast => 8,
    MealSlot.lunch => 13,
    MealSlot.dinner => 19,
  };
}

/// How long before a meal the cook reminder fires.
const cookReminderLead = Duration(hours: 1);

/// The next time, at or after [now], to remind the user to cook the meal in
/// [day]/[slot]. The plan repeats weekly, so this is at most 7 days away.
DateTime nextCookReminder(PlanDay day, MealSlot slot, DateTime now) {
  final reminderHour = slot.hour - cookReminderLead.inHours;
  final daysAhead = (day.weekday - now.weekday) % DateTime.daysPerWeek;
  var candidate = DateTime(
    now.year,
    now.month,
    now.day + daysAhead,
    reminderHour,
  );
  if (candidate.isBefore(now)) {
    candidate = DateTime(
      candidate.year,
      candidate.month,
      candidate.day + DateTime.daysPerWeek,
      reminderHour,
    );
  }
  return candidate;
}
