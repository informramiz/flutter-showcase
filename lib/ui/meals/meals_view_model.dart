import 'dart:async';

import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/ui/core/async_result.dart';
import 'package:flutter_showcase/ui/meals/meals_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meals_view_model.g.dart';

const searchDebounce = Duration(milliseconds: 350);

/// View model of the Meals screen: owns search, category filter and the
/// list's loading state. The view only renders [MealsUiState] and calls the
/// commands below.
@Riverpod(keepAlive: true)
class MealsViewModel extends _$MealsViewModel {
  Timer? _debounce;
  var _generation = 0;

  @override
  MealsUiState build() {
    final favourites = ref.watch(favouritesRepositoryProvider);
    final subscription = favourites.changes.listen(
      (items) => state = state.copyWith(favouriteIds: _ids(items)),
    );
    ref.onDispose(() {
      _debounce?.cancel();
      unawaited(subscription.cancel());
    });
    // Kick off the first loads once the initial state is in place.
    unawaited(Future.microtask(_loadInitial));
    return MealsUiState(
      meals: const AsyncLoading(),
      categories: const AsyncLoading(),
      favouriteIds: _ids(favourites.favourites),
    );
  }

  /// Command: the search field changed. Debounced before hitting the network.
  void search(String query) {
    state = state.copyWith(query: query);
    _reload();
  }

  /// Command: a category chip was tapped (`null` selects "All").
  void selectCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
    _reload();
  }

  /// Command: the retry button on the error view.
  void retry() => _reload();

  /// Command: the heart on a meal card.
  Future<void> toggleFavourite(Meal meal) =>
      ref.read(favouritesRepositoryProvider).toggle(meal);

  Set<String> _ids(List<Meal> items) => {for (final m in items) m.id};

  Future<void> _loadInitial() async {
    unawaited(_loadMeals(_generation));
    final categories = await ref.read(mealRepositoryProvider).categories();
    if (!ref.mounted) return;
    state = state.copyWith(categories: categories.toAsyncValue());
  }

  /// Each call supersedes the previous one: stale timers and responses are
  /// dropped, so only the run that survives [searchDebounce] hits the network.
  void _reload() {
    _debounce?.cancel();
    final generation = ++_generation;
    state = state.copyWith(meals: const AsyncLoading());
    if (state.query.trim().isEmpty) {
      unawaited(_loadMeals(generation));
    } else {
      _debounce = Timer(
        searchDebounce,
        () => unawaited(_loadMeals(generation)),
      );
    }
  }

  Future<void> _loadMeals(int generation) async {
    final result = await _fetch(state.query.trim(), state.selectedCategory);
    if (!ref.mounted || generation != _generation) return;
    state = state.copyWith(meals: result.toAsyncValue());
  }

  Future<Result<List<Meal>>> _fetch(String query, String? category) async {
    final repository = ref.read(mealRepositoryProvider);
    if (query.isEmpty) {
      return category == null
          ? repository.search('')
          : repository.byCategory(category);
    }
    final found = await repository.search(query);
    // Search results carry their category, so narrow them client-side.
    return found.map(
      (meals) => category == null
          ? meals
          : meals.where((m) => m.category == category).toList(),
    );
  }
}
