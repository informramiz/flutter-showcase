import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_detail_ui_state.freezed.dart';

/// Everything the Meal detail screen renders, as one immutable value.
@freezed
abstract class MealDetailUiState with _$MealDetailUiState {
  const factory MealDetailUiState({
    required AsyncValue<Meal> meal,
    @Default(false) bool isFavourite,
  }) = _MealDetailUiState;
}
