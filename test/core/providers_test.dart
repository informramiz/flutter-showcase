import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/core/network/dio_provider.dart';
import 'package:flutter_showcase/core/network/failure_interceptor.dart';
import 'package:flutter_showcase/core/storage/preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
