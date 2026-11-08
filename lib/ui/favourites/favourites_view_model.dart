import 'dart:async';

import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/ui/favourites/favourites_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favourites_view_model.g.dart';

/// View model of the Favourites screen. The database is the source of
/// truth; this mirrors its stream into [FavouritesUiState].
@Riverpod(keepAlive: true)
class FavouritesViewModel extends _$FavouritesViewModel {
  @override
  FavouritesUiState build() {
    final subscription = ref
        .watch(favouritesRepositoryProvider)
        .watchFavourites()
        .listen(
          (items) => state = FavouritesUiState(meals: AsyncData(items)),
          onError: (Object error, StackTrace stack) =>
              state = FavouritesUiState(meals: AsyncError(error, stack)),
        );
    ref.onDispose(() => unawaited(subscription.cancel()));
    return const FavouritesUiState();
  }

  /// Command: the heart on a meal card.
  Future<void> toggleFavourite(Meal meal) =>
      ref.read(favouritesRepositoryProvider).toggle(meal);
}
