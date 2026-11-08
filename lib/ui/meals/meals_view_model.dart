import 'dart:async';

import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/domain/models/cached.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/ui/core/freshness.dart';
import 'package:flutter_showcase/ui/core/latest_subscription.dart';
import 'package:flutter_showcase/ui/meals/meals_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meals_view_model.g.dart';

const searchDebounce = Duration(milliseconds: 350);

/// View model of the Meals screen: owns search, category filter, the list's
/// loading state and how fresh it is. The view only renders [MealsUiState]
/// and calls the commands below.
@Riverpod(keepAlive: true)
class MealsViewModel extends _$MealsViewModel {
  final _meals = LatestSubscription<Result<Cached<List<Meal>>>>();
  final _categories = LatestSubscription<Result<Cached<List<String>>>>();
  Timer? _debounce;

  @override
  MealsUiState build() {
    final favourites = ref
        .watch(favouritesRepositoryProvider)
        .watchFavourites()
        .listen(
          (items) => state = state.copyWith(
            favouriteIds: {for (final m in items) m.id},
          ),
        );
    ref.onDispose(() {
      _debounce?.cancel();
      _meals.cancel();
      _categories.cancel();
      unawaited(favourites.cancel());
    });
    // Kick off the first loads once the initial state is in place.
    unawaited(
      Future.microtask(() {
        unawaited(_loadCategories());
        unawaited(_loadMeals());
      }),
    );
    return const MealsUiState(
      meals: AsyncLoading(),
      categories: AsyncLoading(),
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

  /// Command: pull to refresh. Skips the cache and completes once the
  /// network has answered.
  Future<void> refresh() async {
    _debounce?.cancel();
    await Future.wait([
      _loadCategories(forceRefresh: true),
      _loadMeals(forceRefresh: true),
    ]);
  }

  /// Command: the heart on a meal card.
  Future<void> toggleFavourite(Meal meal) =>
      ref.read(favouritesRepositoryProvider).toggle(meal);

  /// Every call supersedes the previous one: the pending debounce and the
  /// running query are dropped, so only the latest input reaches the screen.
  void _reload() {
    _debounce?.cancel();
    _meals.cancel();
    state = state.copyWith(meals: const AsyncLoading());
    if (state.query.trim().isEmpty) {
      unawaited(_loadMeals());
    } else {
      _debounce = Timer(searchDebounce, () => unawaited(_loadMeals()));
    }
  }

  Future<void> _loadCategories({bool forceRefresh = false}) {
    if (!ref.mounted) return Future.value();
    return _categories.listen(
      ref.read(mealRepositoryProvider).categories(forceRefresh: forceRefresh),
      (result) => state = state.copyWith(
        categories: switch (result) {
          Success(value: final cached) => AsyncData(cached.data),
          // Keep chips from an earlier load rather than blanking them.
          Err(:final failure) when !state.categories.hasValue => AsyncError(
            failure,
            StackTrace.empty,
          ),
          Err() => state.categories,
        },
      ),
      onError: (error, stack) =>
          state = state.copyWith(categories: AsyncError(error, stack)),
    );
  }

  Future<void> _loadMeals({bool forceRefresh = false}) {
    if (!ref.mounted) return Future.value();
    return _meals.listen(
      _query(state.query.trim(), state.selectedCategory, forceRefresh),
      (result) => state = switch (result) {
        Success(value: final cached) => state.copyWith(
          meals: AsyncData(cached.data),
          freshness: Freshness.of(cached),
        ),
        Err(:final failure) => state.copyWith(
          meals: AsyncError(failure, StackTrace.empty),
          freshness: const Freshness(),
        ),
      },
      onError: (error, stack) =>
          state = state.copyWith(meals: AsyncError(error, stack)),
    );
  }

  Stream<Result<Cached<List<Meal>>>> _query(
    String query,
    String? category,
    bool forceRefresh,
  ) {
    final repository = ref.read(mealRepositoryProvider);
    if (query.isEmpty) {
      return category == null
          ? repository.search('', forceRefresh: forceRefresh)
          : repository.byCategory(category, forceRefresh: forceRefresh);
    }
    final found = repository.search(query, forceRefresh: forceRefresh);
    if (category == null) return found;
    // Search results carry their category, so narrow them client-side.
    return found.map(
      (result) => result.map(
        (cached) => cached.copyWith(
          data: cached.data.where((m) => m.category == category).toList(),
        ),
      ),
    );
  }
}
