import 'dart:convert';

import 'package:flutter_showcase/core/storage/preferences_provider.dart';
import 'package:flutter_showcase/features/meals/domain/meal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'favourites_repository.g.dart';

const favouritesKey = 'favourites_v1';

/// Persists favourite meals as one JSON list in `shared_preferences`.
///
/// Only the summary fields are stored, which is enough to render the
/// Favourites tab offline. Detail is fetched when a meal is opened.
class FavouritesRepository {
  FavouritesRepository(this._prefs);

  final SharedPreferences _prefs;

  List<Meal> load() {
    final raw = _prefs.getString(favouritesKey);
    if (raw == null) return const [];
    try {
      return [
        for (final item in jsonDecode(raw) as List<dynamic>)
          _fromJson(item as Map<String, dynamic>),
      ];
    } on Object {
      // Corrupt data must never crash the app; start empty instead.
      return const [];
    }
  }

  Future<void> save(List<Meal> meals) => _prefs.setString(
    favouritesKey,
    jsonEncode([for (final m in meals) _toJson(m)]),
  );

  static Map<String, dynamic> _toJson(Meal m) => {
    'id': m.id,
    'name': m.name,
    'thumbnailUrl': m.thumbnailUrl,
    'category': m.category,
  };

  static Meal _fromJson(Map<String, dynamic> json) => Meal(
    id: json['id'] as String,
    name: json['name'] as String,
    thumbnailUrl: json['thumbnailUrl'] as String,
    category: json['category'] as String?,
  );
}

@Riverpod(keepAlive: true)
FavouritesRepository favouritesRepository(Ref ref) =>
    FavouritesRepository(ref.watch(sharedPreferencesProvider));
