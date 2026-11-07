import 'dart:async';

import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/ui/core/async_result.dart';
import 'package:flutter_showcase/ui/meal_detail/meal_detail_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meal_detail_view_model.g.dart';

/// View model of the Meal detail screen, one instance per meal [id].
@riverpod
class MealDetailViewModel extends _$MealDetailViewModel {
  @override
  MealDetailUiState build(String id) {
    final favourites = ref.watch(favouritesRepositoryProvider);
    bool contains(List<Meal> items) => items.any((m) => m.id == id);
    final subscription = favourites.changes.listen(
      (items) => state = state.copyWith(isFavourite: contains(items)),
    );
    ref.onDispose(() => unawaited(subscription.cancel()));
    unawaited(Future.microtask(_load));
    return MealDetailUiState(
      meal: const AsyncLoading(),
      isFavourite: contains(favourites.favourites),
    );
  }

  /// Command: the retry button on the error view.
  void retry() {
    state = state.copyWith(meal: const AsyncLoading());
    unawaited(_load());
  }

  /// Command: the heart in the app bar. No-op until the meal has loaded.
  Future<void> toggleFavourite() async {
    final meal = state.meal.value;
    if (meal == null) return;
    await ref.read(favouritesRepositoryProvider).toggle(meal);
  }

  Future<void> _load() async {
    final result = await ref.read(mealRepositoryProvider).meal(id);
    if (!ref.mounted) return;
    state = state.copyWith(meal: result.toAsyncValue());
  }
}
