import 'dart:async';

import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/ui/favourites/favourites_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favourites_view_model.g.dart';

/// View model of the Favourites screen. The repository is the source of
/// truth; this mirrors it into [FavouritesUiState].
@Riverpod(keepAlive: true)
class FavouritesViewModel extends _$FavouritesViewModel {
  @override
  FavouritesUiState build() {
    final favourites = ref.watch(favouritesRepositoryProvider);
    final subscription = favourites.changes.listen(
      (items) => state = FavouritesUiState(meals: items),
    );
    ref.onDispose(() => unawaited(subscription.cancel()));
    return FavouritesUiState(meals: favourites.favourites);
  }

  /// Command: the heart on a meal card.
  Future<void> toggleFavourite(Meal meal) =>
      ref.read(favouritesRepositoryProvider).toggle(meal);
}
