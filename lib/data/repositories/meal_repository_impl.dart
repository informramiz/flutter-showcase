import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/core/time/clock.dart';
import 'package:flutter_showcase/data/database/meal_cache_dao.dart';
import 'package:flutter_showcase/data/models/meal_dto.dart';
import 'package:flutter_showcase/data/repositories/stale_while_revalidate.dart';
import 'package:flutter_showcase/data/services/meal_api_service.dart';
import 'package:flutter_showcase/domain/models/cached.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/repositories/meal_repository.dart';

/// Offline-first meals: the database is the source of truth and the API
/// only ever refreshes it.
class MealRepositoryImpl implements MealRepository {
  MealRepositoryImpl(this._api, this._cache, this._clock);

  final MealApiService _api;
  final MealCacheDao _cache;
  final Clock _clock;

  @override
  Stream<Result<Cached<List<String>>>> categories({
    bool forceRefresh = false,
  }) => staleWhileRevalidate(
    readCache: _cache.categoryNames,
    fetchAndSave: (now) async {
      final names = await _api.categories();
      await _cache.saveCategories(names, now);
      return names;
    },
    maxAge: CachePolicy.lists,
    clock: _clock,
    forceRefresh: forceRefresh,
  );

  @override
  Stream<Result<Cached<List<Meal>>>> search(
    String query, {
    bool forceRefresh = false,
  }) {
    final key = searchKey(query);
    return staleWhileRevalidate(
      readCache: () => _cache.mealsForQuery(key),
      fetchAndSave: (now) async {
        final dtos = await _api.search(query.trim());
        final meals = dtos.map((d) => d.toDomain()).toList();
        await _cache.saveQuery(key, meals, now);
        return meals;
      },
      maxAge: CachePolicy.lists,
      clock: _clock,
      forceRefresh: forceRefresh,
      offlineFallback: () async => _nonEmpty(await _cache.searchLocal(query)),
    );
  }

  @override
  Stream<Result<Cached<List<Meal>>>> byCategory(
    String category, {
    bool forceRefresh = false,
  }) {
    final key = categoryKey(category);
    return staleWhileRevalidate(
      readCache: () => _cache.mealsForQuery(key),
      fetchAndSave: (now) async {
        final dtos = await _api.byCategory(category);
        // The filter endpoint omits the category, so fill it in.
        final meals = [
          for (final d in dtos) d.toDomain().copyWith(category: category),
        ];
        await _cache.saveQuery(key, meals, now);
        return meals;
      },
      maxAge: CachePolicy.lists,
      clock: _clock,
      forceRefresh: forceRefresh,
      offlineFallback: () async =>
          _nonEmpty(await _cache.mealsInCategory(category)),
    );
  }

  @override
  Stream<Result<Cached<Meal>>> meal(String id, {bool forceRefresh = false}) =>
      staleWhileRevalidate(
        readCache: () => _cache.mealDetail(id),
        fetchAndSave: (now) async {
          final meal = (await _api.lookup(id)).toDomain();
          await _cache.saveMealDetail(meal, now);
          return meal;
        },
        maxAge: CachePolicy.detail,
        clock: _clock,
        forceRefresh: forceRefresh,
      );

  static List<Meal>? _nonEmpty(List<Meal> meals) =>
      meals.isEmpty ? null : meals;
}
