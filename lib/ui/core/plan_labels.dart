import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_showcase/l10n/app_localizations.dart';

/// Localised names of plan days and meal slots.
extension PlanLabels on AppLocalizations {
  String dayName(PlanDay day) => switch (day) {
    PlanDay.monday => monday,
    PlanDay.tuesday => tuesday,
    PlanDay.wednesday => wednesday,
    PlanDay.thursday => thursday,
    PlanDay.friday => friday,
    PlanDay.saturday => saturday,
    PlanDay.sunday => sunday,
  };

  String slotName(MealSlot slot) => switch (slot) {
    MealSlot.breakfast => breakfast,
    MealSlot.lunch => lunch,
    MealSlot.dinner => dinner,
  };
}
