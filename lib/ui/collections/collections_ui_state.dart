import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/models/meal_collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'collections_ui_state.freezed.dart';

/// Everything the Collections tab renders.
@freezed
abstract class CollectionsUiState with _$CollectionsUiState {
  const factory CollectionsUiState({
    @Default(AsyncLoading<List<MealCollection>>())
    AsyncValue<List<MealCollection>> collections,
  }) = _CollectionsUiState;
}

/// Everything one collection's page renders. [collection] is `null` once
/// the collections have loaded and this id is not among them.
@freezed
abstract class CollectionDetailUiState with _$CollectionDetailUiState {
  const factory CollectionDetailUiState({
    @Default(AsyncLoading<List<Meal>>()) AsyncValue<List<Meal>> meals,
    MealCollection? collection,
    @Default(false) bool collectionLoaded,
  }) = _CollectionDetailUiState;
}

/// The "Save to collection" sheet: every collection, and which ones hold
/// the meal.
@freezed
abstract class SaveToCollectionUiState with _$SaveToCollectionUiState {
  const factory SaveToCollectionUiState({
    @Default(AsyncLoading<List<MealCollection>>())
    AsyncValue<List<MealCollection>> collections,
    @Default(<int>{}) Set<int> selectedIds,
  }) = _SaveToCollectionUiState;
}
