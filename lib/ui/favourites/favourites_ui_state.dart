import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'favourites_ui_state.freezed.dart';

/// Everything the Favourites screen renders, as one immutable value.
@freezed
abstract class FavouritesUiState with _$FavouritesUiState {
  const factory FavouritesUiState({
    @Default(AsyncLoading<List<Meal>>()) AsyncValue<List<Meal>> meals,
  }) = _FavouritesUiState;
}
