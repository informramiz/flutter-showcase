// Composition root: the one place that knows both the domain interfaces and
// their data-layer implementations. The UI imports this file and only ever
// sees the interface types (`MealRepository`, `FavouritesRepository`).
// Tests swap any of these with `overrideWithValue`.
import 'package:dio/dio.dart';
import 'package:flutter_showcase/core/network/failure_interceptor.dart';
import 'package:flutter_showcase/data/repositories/favourites_repository_impl.dart';
import 'package:flutter_showcase/data/repositories/meal_repository_impl.dart';
import 'package:flutter_showcase/data/services/connectivity_service.dart';
import 'package:flutter_showcase/data/services/meal_api_service.dart';
import 'package:flutter_showcase/data/services/preferences_service.dart';
import 'package:flutter_showcase/domain/repositories/favourites_repository.dart';
import 'package:flutter_showcase/domain/repositories/meal_repository.dart';
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
MealRepository mealRepository(Ref ref) =>
    MealRepositoryImpl(ref.watch(mealApiServiceProvider));

@Riverpod(keepAlive: true)
FavouritesRepository favouritesRepository(Ref ref) {
  final repository = FavouritesRepositoryImpl(
    ref.watch(preferencesServiceProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
}

/// Emits `true` while the device has some network interface.
@riverpod
Stream<bool> isOnline(Ref ref) =>
    ref.watch(connectivityServiceProvider).onlineChanges();
