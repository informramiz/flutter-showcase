import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/models/meal_collection.dart';
import 'package:flutter_showcase/domain/services/collection_name.dart';
import 'package:flutter_showcase/ui/collections/collections_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'collections_view_model.g.dart';

/// View model of the Collections tab, and the place every screen goes to
/// create, rename or delete a collection, so name rules live in one spot.
@Riverpod(keepAlive: true)
class CollectionsViewModel extends _$CollectionsViewModel {
  @override
  CollectionsUiState build() {
    final subscription = ref
        .watch(collectionsRepositoryProvider)
        .watchCollections()
        .listen(
          (items) => state = CollectionsUiState(collections: AsyncData(items)),
          onError: (Object error, StackTrace stack) =>
              state = CollectionsUiState(collections: AsyncError(error, stack)),
        );
    ref.onDispose(() => unawaited(subscription.cancel()));
    return const CollectionsUiState();
  }

  /// Checks [name] against the rules and the other collections' names.
  /// [renaming] is the collection being renamed, which may keep its name.
  CollectionNameError? validate(String name, {int? renaming}) =>
      validateCollectionName(
        name,
        existing: [
          for (final c in state.collections.value ?? const <MealCollection>[])
            if (c.id != renaming) c.name,
        ],
      );

  /// Command: "New collection". Returns the new id.
  Future<int> create(String name) =>
      ref.read(collectionsRepositoryProvider).create(name);

  Future<void> rename(int id, String name) =>
      ref.read(collectionsRepositoryProvider).rename(id, name);

  Future<void> delete(int id) =>
      ref.read(collectionsRepositoryProvider).delete(id);
}

/// View model of one collection's page.
@riverpod
class CollectionDetailViewModel extends _$CollectionDetailViewModel {
  @override
  CollectionDetailUiState build(int id) {
    final repository = ref.watch(collectionsRepositoryProvider);
    final meals = repository
        .watchMeals(id)
        .listen(
          (items) => state = state.copyWith(meals: AsyncData(items)),
          onError: (Object error, StackTrace stack) =>
              state = state.copyWith(meals: AsyncError(error, stack)),
        );
    ref.onDispose(() => unawaited(meals.cancel()));
    // The tab's view model already holds every collection; reuse it rather
    // than opening a second query.
    final collections = ref.listen(
      collectionsViewModelProvider.select((s) => s.collections.value),
      (_, items) => state = _withCollection(state, items),
    );
    return _withCollection(const CollectionDetailUiState(), collections.read());
  }

  CollectionDetailUiState _withCollection(
    CollectionDetailUiState current,
    List<MealCollection>? all,
  ) => all == null
      ? current
      : current.copyWith(
          collection: all.where((c) => c.id == id).firstOrNull,
          collectionLoaded: true,
        );

  /// Command: the remove button on a meal.
  Future<void> remove(Meal meal) => ref
      .read(collectionsRepositoryProvider)
      .setMembership(id, meal, included: false);
}

/// View model of the "Save to collection" sheet for meal [mealId].
@riverpod
class SaveToCollectionViewModel extends _$SaveToCollectionViewModel {
  @override
  SaveToCollectionUiState build(String mealId) {
    final selected = ref
        .watch(collectionsRepositoryProvider)
        .watchCollectionIdsFor(mealId)
        .listen((ids) => state = state.copyWith(selectedIds: ids));
    ref.onDispose(() => unawaited(selected.cancel()));
    final collections = ref.listen(
      collectionsViewModelProvider.select((s) => s.collections),
      (_, collections) => state = state.copyWith(collections: collections),
    );
    return SaveToCollectionUiState(collections: collections.read());
  }

  /// Command: a checkbox in the sheet.
  Future<void> toggle(MealCollection collection, Meal meal) => ref
      .read(collectionsRepositoryProvider)
      .setMembership(
        collection.id,
        meal,
        included: !state.selectedIds.contains(collection.id),
      );

  /// Command: "New collection" in the sheet. Creates it with [meal] inside.
  Future<void> createWith(String name, Meal meal) async {
    final id = await ref
        .read(collectionsViewModelProvider.notifier)
        .create(
          name,
        );
    await ref
        .read(collectionsRepositoryProvider)
        .setMembership(id, meal, included: true);
  }
}
