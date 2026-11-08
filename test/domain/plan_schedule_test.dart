import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_showcase/domain/services/plan_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-11-04 is a Wednesday.
  final wednesdayMorning = DateTime(2026, 11, 4, 9);

  test('PlanDay.weekday matches DateTime', () {
    expect(PlanDay.monday.weekday, DateTime.monday);
    expect(PlanDay.sunday.weekday, DateTime.sunday);
  });

  test('later the same day', () {
    expect(
      nextCookReminder(PlanDay.wednesday, MealSlot.dinner, wednesdayMorning),
      DateTime(2026, 11, 4, 18),
    );
  });

  test('already passed today rolls to next week', () {
    expect(
      nextCookReminder(
        PlanDay.wednesday,
        MealSlot.breakfast,
        wednesdayMorning,
      ),
      DateTime(2026, 11, 11, 7),
    );
  });

  test('a later weekday this week', () {
    expect(
      nextCookReminder(PlanDay.friday, MealSlot.lunch, wednesdayMorning),
      DateTime(2026, 11, 6, 12),
    );
  });

  test('an earlier weekday wraps into next week and across months', () {
    expect(
      nextCookReminder(PlanDay.monday, MealSlot.dinner, DateTime(2026, 11, 25)),
      DateTime(2026, 11, 30, 18),
    );
    expect(
      nextCookReminder(
        PlanDay.tuesday,
        MealSlot.dinner,
        DateTime(2026, 11, 25),
      ),
      DateTime(2026, 12, 1, 18),
    );
  });

  test('slot hours', () {
    expect(MealSlot.values.map((s) => s.hour), [8, 13, 19]);
  });
}
