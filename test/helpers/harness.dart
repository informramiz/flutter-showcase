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
import 'package:flutter_showcase/domain/models/meal_collection.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_showcase/domain/repositories/collections_repository.dart';
import 'package:flutter_showcase/domain/repositories/favourites_repository.dart';
import 'package:flutter_showcase/domain/repositories/meal_repository.dart';
import 'package:flutter_showcase/domain/repositories/planner_repository.dart';
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

/// In-memory plan. Writes update the emitted plan and are logged in
/// [calls] so tests can assert on the exact command.
class FakePlannerRepository implements PlannerRepository {
  FakePlannerRepository([
    List<PlannedMeal> plan = const [],
    Set<String> checked = const {},
  ]) : _plan = [...plan],
       _checked = {...checked};

  List<PlannedMeal> _plan;
  Set<String> _checked;
  final calls = <String>[];
  final _planChanges = StreamController<List<PlannedMeal>>.broadcast(
    sync: true,
  );
  final _checkChanges = StreamController<Set<String>>.broadcast(sync: true);

  @override
  Stream<List<PlannedMeal>> watchPlan() async* {
    yield _plan;
    yield* _planChanges.stream;
  }

  @override
  Stream<Set<String>> watchCheckedKeys() async* {
    yield _checked;
    yield* _checkChanges.stream;
  }

  @override
  Future<int> add(Meal meal, PlanDay day, MealSlot slot) async {
    calls.add('add ${meal.id} ${day.name} ${slot.name}');
    final id = _plan.length + 1;
    final position = _plan.where((e) => e.day == day && e.slot == slot);
    _plan = [
      ..._plan,
      PlannedMeal(
        entryId: id,
        day: day,
        slot: slot,
        position: position.length,
        meal: meal,
      ),
    ];
    _planChanges.add(_plan);
    return id;
  }

  @override
  Future<void> move(int entryId, PlanDay day, MealSlot slot, int index) async {
    calls.add('move $entryId ${day.name} ${slot.name} $index');
  }

  @override
  Future<void> remove(int entryId) async {
    calls.add('remove $entryId');
    _plan = [
      for (final e in _plan)
        if (e.entryId != entryId) e,
    ];
    _planChanges.add(_plan);
  }

  @override
  Future<void> setReminder(int entryId, {required bool enabled}) async {
    calls.add('reminder $entryId $enabled');
  }

  @override
  Future<void> setChecked(String key, {required bool checked}) async {
    _checked = checked ? {..._checked, key} : ({..._checked}..remove(key));
    _checkChanges.add(_checked);
  }

  @override
  Future<void> uncheckAll() async {
    _checked = {};
    _checkChanges.add(_checked);
  }
}

/// In-memory collections with the same contract as the database version.
class FakeCollectionsRepository implements CollectionsRepository {
  FakeCollectionsRepository([
    Map<MealCollection, List<Meal>> initial = const {},
  ]) {
    for (final MapEntry(key: c, value: meals) in initial.entries) {
      _names[c.id] = c.name;
      _meals[c.id] = [...meals];
    }
  }

  final _names = <int, String>{};
  final _meals = <int, List<Meal>>{};
  final _changes = StreamController<void>.broadcast(sync: true);

  List<MealCollection> get _collections =>
      [
        for (final MapEntry(key: id, value: name) in _names.entries)
          MealCollection(id: id, name: name, mealCount: _meals[id]!.length),
      ]..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Stream<List<MealCollection>> watchCollections() => _watch(() => _collections);

  @override
  Stream<List<Meal>> watchMeals(int collectionId) =>
      _watch(() => [...?_meals[collectionId]]);

  @override
  Stream<Set<int>> watchCollectionIdsFor(String mealId) => _watch(
    () => {
      for (final MapEntry(key: id, value: meals) in _meals.entries)
        if (meals.any((m) => m.id == mealId)) id,
    },
  );

  @override
  Future<int> create(String name) async {
    final id = (_names.keys.fold(0, (a, b) => a > b ? a : b)) + 1;
    _names[id] = name.trim();
    _meals[id] = [];
    _changes.add(null);
    return id;
  }

  @override
  Future<void> rename(int collectionId, String name) async {
    _names[collectionId] = name.trim();
    _changes.add(null);
  }

  @override
  Future<void> delete(int collectionId) async {
    _names.remove(collectionId);
    _meals.remove(collectionId);
    _changes.add(null);
  }

  @override
  Future<void> setMembership(
    int collectionId,
    Meal meal, {
    required bool included,
  }) async {
    final meals = _meals[collectionId]!..removeWhere((m) => m.id == meal.id);
    if (included) meals.insert(0, meal);
    _changes.add(null);
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
  PlannerRepository? plannerRepository,
  CollectionsRepository? collectionsRepository,
}) async => [
  sharedPreferencesProvider.overrideWithValue(await fakePrefs(prefs)),
  clockProvider.overrideWithValue(() => testNow),
  mealRepositoryProvider.overrideWithValue(repository),
  favouritesRepositoryProvider.overrideWithValue(
    favouritesRepository ?? FakeFavouritesRepository(favourites),
  ),
  plannerRepositoryProvider.overrideWithValue(
    plannerRepository ?? FakePlannerRepository(),
  ),
  collectionsRepositoryProvider.overrideWithValue(
    collectionsRepository ?? FakeCollectionsRepository(),
  ),
  isOnlineProvider.overrideWith((ref) => Stream.value(online)),
];

Future<ProviderContainer> makeContainer(
  MealRepository repository, {
  List<Meal> favourites = const [],
  Map<String, Object> prefs = const {},
  FavouritesRepository? favouritesRepository,
  PlannerRepository? plannerRepository,
  CollectionsRepository? collectionsRepository,
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
        plannerRepository: plannerRepository,
        collectionsRepository: collectionsRepository,
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
  PlannerRepository? plannerRepository,
  CollectionsRepository? collectionsRepository,
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
          plannerRepository: plannerRepository,
          collectionsRepository: collectionsRepository,
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
  PlannerRepository? plannerRepository,
  CollectionsRepository? collectionsRepository,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: noRetry,
      overrides: [
        ...await baseOverrides(
          repository,
          favourites: favourites,
          plannerRepository: plannerRepository,
          collectionsRepository: collectionsRepository,
        ),
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
