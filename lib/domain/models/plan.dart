import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan.freezed.dart';

/// A day of the weekly plan. [weekday] matches `DateTime.monday` (1) to
/// `DateTime.sunday` (7).
enum PlanDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday
  ;

  int get weekday => index + 1;
}

/// A meal slot within a day.
enum MealSlot { breakfast, lunch, dinner }

/// One meal placed on the weekly plan.
@freezed
abstract class PlannedMeal with _$PlannedMeal {
  const factory PlannedMeal({
    required int entryId,
    required PlanDay day,
    required MealSlot slot,

    /// Order within the day and slot, starting at 0.
    required int position,

    /// The meal, with ingredients when its detail has been cached.
    required Meal meal,
    @Default(false) bool reminderEnabled,
  }) = _PlannedMeal;
}
