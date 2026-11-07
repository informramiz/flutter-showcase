import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_showcase/app.dart';
import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/repositories/meal_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

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

/// A repository that returns [meals] for every list call.
MockMealRepository stubbedRepository({
  List<Meal> meals = const [pasta, curry],
  List<String> categories = const ['Pasta', 'Chicken'],
}) {
  final repository = MockMealRepository();
  when(repository.categories).thenAnswer((_) async => Success(categories));
  when(() => repository.search(any())).thenAnswer((_) async => Success(meals));
  when(
    () => repository.byCategory(any()),
  ).thenAnswer((_) async => Success(meals));
  when(
    () => repository.meal(any()),
  ).thenAnswer((_) async => const Success(pastaDetail));
  return repository;
}
