import 'package:flutter_showcase/domain/models/meal.dart';

/// The user's favourite meals. Implementations own persistence and are the
/// single source of truth; view models subscribe to [changes].
abstract interface class FavouritesRepository {
  /// Favourites right now, newest first.
  List<Meal> get favourites;

  /// Emits the full list after every [toggle].
  Stream<List<Meal>> get changes;

  /// Adds [meal], or removes it when it is already a favourite.
  Future<void> toggle(Meal meal);
}
