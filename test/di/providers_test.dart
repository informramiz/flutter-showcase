import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/core/network/failure_interceptor.dart';
import 'package:flutter_showcase/data/services/meal_api_service.dart';
import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/domain/repositories/favourites_repository.dart';
import 'package:flutter_showcase/domain/repositories/meal_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('dioProvider points at TheMealDB and installs the interceptor', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dio = container.read(dioProvider);

    expect(dio.options.baseUrl, mealDbBaseUrl);
    expect(dio.options.connectTimeout, isNotNull);
    expect(dio.interceptors.whereType<FailureInterceptor>(), hasLength(1));
    expect(dio, isA<Dio>());
  });

  test('sharedPreferencesProvider must be overridden', () {
    final container = ProviderContainer(retry: (_, _) => null);
    addTearDown(container.dispose);

    expect(
      () => container.read(sharedPreferencesProvider),
      throwsA(anything),
    );
  });

  test('repositories are wired and typed as their domain interfaces', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(mealRepositoryProvider), isA<MealRepository>());
    expect(
      container.read(favouritesRepositoryProvider),
      isA<FavouritesRepository>(),
    );
    expect(container.read(connectivityServiceProvider), isNotNull);
  });
}
