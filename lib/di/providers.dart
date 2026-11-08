// Composition root: the one place that knows both the domain interfaces and
// their data-layer implementations. The UI imports this file and only ever
// sees the interface types (`MealRepository`, `FavouritesRepository`).
// Tests swap any of these with `overrideWithValue`.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_showcase/core/network/failure_interceptor.dart';
import 'package:flutter_showcase/core/time/clock.dart';
import 'package:flutter_showcase/data/database/app_database.dart';
import 'package:flutter_showcase/data/database/collections_dao.dart';
import 'package:flutter_showcase/data/database/meal_cache_dao.dart';
import 'package:flutter_showcase/data/database/planner_dao.dart';
import 'package:flutter_showcase/data/repositories/collections_repository_impl.dart';
import 'package:flutter_showcase/data/repositories/favourites_repository_impl.dart';
import 'package:flutter_showcase/data/repositories/meal_repository_impl.dart';
import 'package:flutter_showcase/data/repositories/planner_repository_impl.dart';
import 'package:flutter_showcase/data/services/connectivity_service.dart';
import 'package:flutter_showcase/data/services/meal_api_service.dart';
import 'package:flutter_showcase/data/services/preferences_service.dart';
import 'package:flutter_showcase/domain/repositories/collections_repository.dart';
import 'package:flutter_showcase/domain/repositories/favourites_repository.dart';
import 'package:flutter_showcase/domain/repositories/meal_repository.dart';
import 'package:flutter_showcase/domain/repositories/planner_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'providers.g.dart';

// Infrastructure -------------------------------------------------------

/// Overridden in `main()` with the instance loaded before `runApp`, which
/// keeps every consumer synchronous.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('Override sharedPreferencesProvider in main().');

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final client = Dio(
    BaseOptions(
      baseUrl: mealDbBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  )..interceptors.add(FailureInterceptor());
  ref.onDispose(client.close);
  return client;
}

@Riverpod(keepAlive: true)
Clock clock(Ref ref) => DateTime.now;

/// The one database connection for the app's lifetime.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final database = AppDatabase();
  ref.onDispose(() => unawaited(database.close()));
  return database;
}

@Riverpod(keepAlive: true)
MealCacheDao mealCacheDao(Ref ref) =>
    ref.watch(appDatabaseProvider).mealCacheDao;

@Riverpod(keepAlive: true)
PlannerDao plannerDao(Ref ref) => ref.watch(appDatabaseProvider).plannerDao;

@Riverpod(keepAlive: true)
CollectionsDao collectionsDao(Ref ref) =>
    ref.watch(appDatabaseProvider).collectionsDao;

// Services -------------------------------------------------------------

@Riverpod(keepAlive: true)
MealApiService mealApiService(Ref ref) =>
    MealApiService(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
PreferencesService preferencesService(Ref ref) =>
    PreferencesService(ref.watch(sharedPreferencesProvider));

@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) => ConnectivityService();

// Repositories (typed as their domain interface) -----------------------

@Riverpod(keepAlive: true)
MealRepository mealRepository(Ref ref) => MealRepositoryImpl(
  ref.watch(mealApiServiceProvider),
  ref.watch(mealCacheDaoProvider),
  ref.watch(clockProvider),
);

@Riverpod(keepAlive: true)
FavouritesRepository favouritesRepository(Ref ref) {
  final repository = FavouritesRepositoryImpl(
    ref.watch(mealCacheDaoProvider),
    ref.watch(preferencesServiceProvider),
    ref.watch(clockProvider),
  );
  unawaited(repository.importLegacy());
  return repository;
}

@Riverpod(keepAlive: true)
PlannerRepository plannerRepository(Ref ref) =>
    PlannerRepositoryImpl(ref.watch(plannerDaoProvider));

@Riverpod(keepAlive: true)
CollectionsRepository collectionsRepository(Ref ref) =>
    CollectionsRepositoryImpl(
      ref.watch(collectionsDaoProvider),
      ref.watch(clockProvider),
    );

/// Emits `true` while the device has some network interface.
@riverpod
Stream<bool> isOnline(Ref ref) =>
    ref.watch(connectivityServiceProvider).onlineChanges();
