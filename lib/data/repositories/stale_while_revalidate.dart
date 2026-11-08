import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/core/time/clock.dart';
import 'package:flutter_showcase/data/database/meal_cache_dao.dart';
import 'package:flutter_showcase/domain/models/cached.dart';

/// How long cached data counts as fresh.
abstract final class CachePolicy {
  /// Lists change when TheMealDB adds recipes, which is rare.
  static const lists = Duration(hours: 1);

  /// A recipe practically never changes once published.
  static const detail = Duration(hours: 24);
}

/// The stale-while-revalidate read every repository method shares.
///
/// 1. A fresh cache hit is emitted and the stream ends (unless
///    [forceRefresh]).
/// 2. A stale hit is emitted with `isRefreshing`, then the network is asked.
/// 3. A successful fetch is written by [fetchAndSave] and emitted.
/// 4. A failed fetch re-emits the cache with `refreshFailure`; without a
///    cache, [offlineFallback] (when non-null) gets a chance, else `Err`.
Stream<Result<Cached<T>>> staleWhileRevalidate<T>({
  required Future<CacheHit<T>?> Function() readCache,
  required Future<T> Function(DateTime now) fetchAndSave,
  required Duration maxAge,
  required Clock clock,
  bool forceRefresh = false,
  Future<T?> Function()? offlineFallback,
}) async* {
  final hit = await readCache();
  if (hit != null) {
    final fresh = clock().difference(hit.fetchedAt) < maxAge;
    if (fresh && !forceRefresh) {
      yield Success(Cached(hit.data, fetchedAt: hit.fetchedAt));
      return;
    }
    yield Success(
      Cached(hit.data, fetchedAt: hit.fetchedAt, isRefreshing: true),
    );
  }
  try {
    final now = clock();
    final data = await fetchAndSave(now);
    yield Success(Cached(data, fetchedAt: now));
  } on AppFailure catch (failure) {
    if (hit != null) {
      yield Success(
        Cached(hit.data, fetchedAt: hit.fetchedAt, refreshFailure: failure),
      );
      return;
    }
    final fallback = await offlineFallback?.call();
    yield fallback == null
        ? Err(failure)
        : Success(Cached(fallback, refreshFailure: failure));
  }
}
