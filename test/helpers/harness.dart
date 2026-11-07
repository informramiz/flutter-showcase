import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/app.dart';
import 'package:flutter_showcase/core/connectivity/connectivity_provider.dart';
import 'package:flutter_showcase/core/storage/preferences_provider.dart';
import 'package:flutter_showcase/features/meals/data/meal_repository_impl.dart';
import 'package:flutter_showcase/features/meals/domain/meal_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMealRepository extends Mock implements MealRepository {}

/// Never auto-retry in tests, so failures surface immediately.
Duration? noRetry(int retryCount, Object error) => null;

Future<SharedPreferences> fakePrefs([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<List<Override>> baseOverrides(
  MealRepository repository, {
  Map<String, Object> prefs = const {},
  bool online = true,
}) async => [
  sharedPreferencesProvider.overrideWithValue(await fakePrefs(prefs)),
  mealRepositoryProvider.overrideWithValue(repository),
  isOnlineProvider.overrideWith((ref) => Stream.value(online)),
];

Future<ProviderContainer> makeContainer(
  MealRepository repository, {
  Map<String, Object> prefs = const {},
}) async {
  final container = ProviderContainer(
    retry: noRetry,
    overrides: await baseOverrides(repository, prefs: prefs),
  );
  addTearDown(container.dispose);
  return container;
}

/// Pumps the whole app (router, theme, shell) with fakes underneath.
Future<void> pumpApp(
  WidgetTester tester,
  MealRepository repository, {
  Map<String, Object> prefs = const {},
  bool online = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: noRetry,
      overrides: await baseOverrides(repository, prefs: prefs, online: online),
      child: const App(),
    ),
  );
  await tester.pump();
}

/// Pumps a single widget inside Material and a ProviderScope.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget child,
  MealRepository repository, {
  Map<String, Object> prefs = const {},
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: noRetry,
      overrides: await baseOverrides(repository, prefs: prefs),
      child: MaterialApp(home: child),
    ),
  );
  await tester.pump();
}
