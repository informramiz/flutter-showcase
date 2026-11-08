import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/ui/core/freshness.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'meals_ui_state.freezed.dart';

/// Everything the Meals screen renders, as one immutable value.
@freezed
abstract class MealsUiState with _$MealsUiState {
  const factory MealsUiState({
    required AsyncValue<List<Meal>> meals,
    required AsyncValue<List<String>> categories,
    @Default(Freshness()) Freshness freshness,
    @Default('') String query,

    /// Selected category chip, or `null` for "All".
    String? selectedCategory,
    @Default(<String>{}) Set<String> favouriteIds,
  }) = _MealsUiState;
}
