import 'dart:async';
import 'dart:convert';

import 'package:flutter_showcase/data/services/preferences_service.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/repositories/favourites_repository.dart';

const favouritesKey = 'favourites_v1';

/// Persists favourite meals as one JSON list through [PreferencesService].
///
/// Only the summary fields are stored, which is enough to render the
/// Favourites tab offline. Detail is fetched when a meal is opened.
class FavouritesRepositoryImpl implements FavouritesRepository {
  FavouritesRepositoryImpl(this._prefs) : _items = _load(_prefs);

  final PreferencesService _prefs;
  final _controller = StreamController<List<Meal>>.broadcast(sync: true);
  List<Meal> _items;

  @override
  List<Meal> get favourites => _items;

  @override
  Stream<List<Meal>> get changes => _controller.stream;

  @override
  Future<void> toggle(Meal meal) {
    final exists = _items.any((m) => m.id == meal.id);
    _items = exists
        ? [
            for (final m in _items)
              if (m.id != meal.id) m,
          ]
        : [meal, ..._items];
    _controller.add(_items);
    return _prefs.setString(
      favouritesKey,
      jsonEncode([for (final m in _items) _toJson(m)]),
    );
  }

  /// Closes [changes]. Called by the DI container on disposal.
  Future<void> dispose() => _controller.close();

  static List<Meal> _load(PreferencesService prefs) {
    final raw = prefs.getString(favouritesKey);
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
