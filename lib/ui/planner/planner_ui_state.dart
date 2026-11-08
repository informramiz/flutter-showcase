import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'planner_ui_state.freezed.dart';

/// Everything the Planner screen renders, as one immutable value.
@freezed
abstract class PlannerUiState with _$PlannerUiState {
  const factory PlannerUiState({
    @Default(AsyncLoading<List<PlannedMeal>>())
    AsyncValue<List<PlannedMeal>> plan,
  }) = _PlannerUiState;
}
