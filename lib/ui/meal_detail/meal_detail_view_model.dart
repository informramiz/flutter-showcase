import 'dart:async';

import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/domain/models/cached.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_showcase/ui/core/freshness.dart';
import 'package:flutter_showcase/ui/core/latest_subscription.dart';
import 'package:flutter_showcase/ui/meal_detail/meal_detail_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meal_detail_view_model.g.dart';

/// View model of the Meal detail screen, one instance per meal [id].
@riverpod
class MealDetailViewModel extends _$MealDetailViewModel {
  final _meal = LatestSubscription<Result<Cached<Meal>>>();

  @override
  MealDetailUiState build(String id) {
    final favourites = ref
        .watch(favouritesRepositoryProvider)
        .watchFavourites()
        .listen(
          (items) => state = state.copyWith(
            isFavourite: items.any((m) => m.id == id),
          ),
        );
    ref.onDispose(() {
      unawaited(favourites.cancel());
      _meal.cancel();
    });
    unawaited(Future.microtask(_load));
    return const MealDetailUiState(meal: AsyncLoading());
  }

  /// Command: the retry button on the error view.
  void retry() {
    state = state.copyWith(meal: const AsyncLoading());
    unawaited(_load());
  }

  /// Command: pull to refresh. Completes when the refresh has finished.
  Future<void> refresh() => _load(forceRefresh: true);

  /// Command: the heart in the app bar. No-op until the meal has loaded.
  Future<void> toggleFavourite() async {
    final meal = state.meal.value;
    if (meal == null) return;
    await ref.read(favouritesRepositoryProvider).toggle(meal);
  }

  /// Command: "Add to plan". Returns false until the meal has loaded.
  Future<bool> addToPlan(PlanDay day, MealSlot slot) async {
    final meal = state.meal.value;
    if (meal == null) return false;
    await ref.read(plannerRepositoryProvider).add(meal, day, slot);
    return true;
  }

  Future<void> _load({bool forceRefresh = false}) {
    if (!ref.mounted) return Future.value();
    return _meal.listen(
      ref.read(mealRepositoryProvider).meal(id, forceRefresh: forceRefresh),
      (result) => state = switch (result) {
        Success(value: final cached) => state.copyWith(
          meal: AsyncData(cached.data),
          freshness: Freshness.of(cached),
        ),
        Err(:final failure) => state.copyWith(
          meal: AsyncError(failure, StackTrace.empty),
          freshness: const Freshness(),
        ),
      },
      onError: (error, stack) =>
          state = state.copyWith(meal: AsyncError(error, stack)),
    );
  }
}
