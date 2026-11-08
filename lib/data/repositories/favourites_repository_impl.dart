import 'dart:convert';

import 'package:flutter_showcase/core/time/clock.dart';
import 'package:flutter_showcase/data/database/meal_cache_dao.dart';
import 'package:flutter_showcase/data/services/preferences_service.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/repositories/favourites_repository.dart';

/// Where favourites lived before the database: one JSON list in
/// shared_preferences. Read once by [FavouritesRepositoryImpl.importLegacy].
const legacyFavouritesKey = 'favourites_v1';

class FavouritesRepositoryImpl implements FavouritesRepository {
  FavouritesRepositoryImpl(this._cache, this._prefs, this._clock);

  final MealCacheDao _cache;
  final PreferencesService _prefs;
  final Clock _clock;

  @override
  Stream<List<Meal>> watchFavourites() => _cache.watchFavourites();

  @override
  Future<void> toggle(Meal meal) => _cache.toggleFavourite(meal, _clock());

  /// Moves favourites saved by earlier versions into the database, keeping
  /// their order, then deletes the old key. Corrupt data is dropped rather
  /// than crashing start-up.
  Future<void> importLegacy() async {
    final raw = _prefs.getString(legacyFavouritesKey);
    if (raw == null) return;
    final List<Meal> meals;
    try {
      meals = [
        for (final item in jsonDecode(raw) as List<dynamic>)
          _fromJson(item as Map<String, dynamic>),
      ];
    } on Object {
      await _prefs.remove(legacyFavouritesKey);
      return;
    }
    // The list was stored newest first; older items get earlier timestamps.
    final now = _clock();
    for (final (i, meal) in meals.indexed) {
      await _cache.addFavourite(
        meal,
        now.subtract(Duration(milliseconds: i)),
      );
    }
    await _prefs.remove(legacyFavouritesKey);
  }

  static Meal _fromJson(Map<String, dynamic> json) => Meal(
    id: json['id'] as String,
    name: json['name'] as String,
    thumbnailUrl: json['thumbnailUrl'] as String,
    category: json['category'] as String?,
  );
}
