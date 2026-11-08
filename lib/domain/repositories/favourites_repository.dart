import 'package:flutter_showcase/domain/models/meal.dart';

/// The user's favourite meals, stored in the local database.
abstract interface class FavouritesRepository {
  /// Favourites, newest first. Emits the current list on listen and again
  /// after every change.
  Stream<List<Meal>> watchFavourites();

  /// Adds [meal], or removes it when it is already a favourite.
  Future<void> toggle(Meal meal);
}
