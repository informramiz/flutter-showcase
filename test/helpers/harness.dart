import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_showcase/app.dart';
import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/domain/models/cached.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/repositories/favourites_repository.dart';
import 'package:flutter_showcase/domain/repositories/meal_repository.dart';
import 'package:flutter_showcase/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

/// English strings, for finding text in tests.
final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

class MockMealRepository extends Mock implements MealRepository {}

/// The instant every test treats as "now".
final testNow = DateTime(2026, 11, 8, 12);

/// One fresh emission, as a repository returns for a fresh cache hit.
Stream<Result<Cached<T>>> fresh<T>(T data) =>
    Stream.value(Success(Cached(data, fetchedAt: testNow)));

/// A stream that fails with [failure] and has nothing cached.
Stream<Result<Cached<T>>> failed<T>(AppFailure failure) =>
    Stream.value(Err(failure));

/// In-memory favourites with the same contract as the database version.
class FakeFavouritesRepository implements FavouritesRepository {
  FakeFavouritesRepository([List<Meal> initial = const []])
    : _items = [...initial];

  List<Meal> _items;
  final _changes = StreamController<List<Meal>>.broadcast(sync: true);

  @override
  Stream<List<Meal>> watchFavourites() async* {
    yield _items;
    yield* _changes.stream;
  }

  @override
  Future<void> toggle(Meal meal) async {
    _items = _items.any((m) => m.id == meal.id)
        ? [
            for (final m in _items)
              if (m.id != meal.id) m,
          ]
        : [meal, ..._items];
    _changes.add(_items);
  }
}

/// Never auto-retry in tests, so failures surface immediately.
Duration? noRetry(int retryCount, Object error) => null;

Future<SharedPreferences> fakePrefs([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<List<Override>> baseOverrides(
  MealRepository repository, {
  List<Meal> favourites = const [],
  bool online = true,
  Map<String, Object> prefs = const {},
  FavouritesRepository? favouritesRepository,
}) async => [
  sharedPreferencesProvider.overrideWithValue(await fakePrefs(prefs)),
  clockProvider.overrideWithValue(() => testNow),
  mealRepositoryProvider.overrideWithValue(repository),
  favouritesRepositoryProvider.overrideWithValue(
    favouritesRepository ?? FakeFavouritesRepository(favourites),
  ),
  isOnlineProvider.overrideWith((ref) => Stream.value(online)),
];

Future<ProviderContainer> makeContainer(
  MealRepository repository, {
  List<Meal> favourites = const [],
  Map<String, Object> prefs = const {},
  FavouritesRepository? favouritesRepository,
  List<Override> overrides = const [],
}) async {
  final container = ProviderContainer(
    retry: noRetry,
    overrides: [
      ...await baseOverrides(
        repository,
        favourites: favourites,
        prefs: prefs,
        favouritesRepository: favouritesRepository,
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Pumps the whole app (router, theme, shell) with fakes underneath.
Future<void> pumpApp(
  WidgetTester tester,
  MealRepository repository, {
  List<Meal> favourites = const [],
  bool online = true,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: noRetry,
      overrides: [
        ...await baseOverrides(
          repository,
          favourites: favourites,
          online: online,
        ),
        ...overrides,
      ],
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
  List<Meal> favourites = const [],
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: noRetry,
      overrides: [
        ...await baseOverrides(repository, favourites: favourites),
        ...overrides,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pump();
}

/// Matches any value of the `forceRefresh` flag.
bool get anyForce => any(named: 'forceRefresh');

/// A repository that returns fresh [meals] for every list call.
MockMealRepository stubbedRepository({
  List<Meal> meals = const [pasta, curry],
  List<String> categories = const ['Pasta', 'Chicken'],
}) {
  final repository = MockMealRepository();
  when(
    () => repository.categories(forceRefresh: anyForce),
  ).thenAnswer((_) => fresh(categories));
  when(
    () => repository.search(any(), forceRefresh: anyForce),
  ).thenAnswer((_) => fresh(meals));
  when(
    () => repository.byCategory(any(), forceRefresh: anyForce),
  ).thenAnswer((_) => fresh(meals));
  when(
    () => repository.meal(any(), forceRefresh: anyForce),
  ).thenAnswer((_) => fresh(pastaDetail));
  return repository;
}
