import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/domain/models/cached.dart';
import 'package:flutter_showcase/domain/models/meal.dart';

/// Offline-first access to TheMealDB.
///
/// Every read is a stream: the cached copy first (if any), then the fresh
/// one when the cache was stale. A stream ends
/// with an `Err` only when there is nothing local to show.
///
/// Pass `forceRefresh` to skip a fresh cache, as pull-to-refresh does.
abstract interface class MealRepository {
  Stream<Result<Cached<List<String>>>> categories({bool forceRefresh = false});

  /// Meals whose name contains [query]. An empty query returns a default set.
  Stream<Result<Cached<List<Meal>>>> search(
    String query, {
    bool forceRefresh = false,
  });

  Stream<Result<Cached<List<Meal>>>> byCategory(
    String category, {
    bool forceRefresh = false,
  });

  Stream<Result<Cached<Meal>>> meal(String id, {bool forceRefresh = false});
}
