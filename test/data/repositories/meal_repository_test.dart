import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/data/database/meal_cache_dao.dart';
import 'package:flutter_showcase/data/models/meal_dto.dart';
import 'package:flutter_showcase/data/repositories/meal_repository_impl.dart';
import 'package:flutter_showcase/data/repositories/stale_while_revalidate.dart';
import 'package:flutter_showcase/data/services/meal_api_service.dart';
import 'package:flutter_showcase/domain/models/cached.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/database.dart';
import '../../helpers/fixtures.dart';

class MockMealApiService extends Mock implements MealApiService {}

void main() {
  late MockMealApiService api;
  late MealCacheDao cache;
  late DateTime now;
  late MealRepositoryImpl repository;

  final start = DateTime(2026, 11, 8, 12);

  setUp(() {
    api = MockMealApiService();
    cache = memoryDatabase().mealCacheDao;
    now = start;
    repository = MealRepositoryImpl(api, cache, () => now);
  });

  /// Unwraps every emission into its [Cached] value, failing on an `Err`.
  Future<List<Cached<T>>> values<T>(Stream<Result<Cached<T>>> s) async => [
    for (final r in await s.toList()) r.getOrThrow(),
  ];

  void stubSearch(String query) => when(
    () => api.search(query),
  ).thenAnswer((_) async => [MealDto.fromJson(mealJson())]);

  group('search', () {
    test('a cold cache fetches, saves and emits once', () async {
      stubSearch('pasta');

      final emitted = await values(repository.search('  pasta '));

      expect(emitted, hasLength(1));
      expect(emitted.single.data.single.name, 'Pasta');
      expect(emitted.single.fetchedAt, start);
      expect(emitted.single.isRefreshing, isFalse);
      expect(
        (await cache.mealsForQuery(searchKey('pasta')))!.data,
        hasLength(1),
      );
    });

    test('a fresh cache is served without touching the network', () async {
      stubSearch('pasta');
      await repository.search('pasta').drain<void>();
      now = start.add(CachePolicy.lists - const Duration(minutes: 1));

      final emitted = await values(repository.search('pasta'));

      expect(emitted.single.fetchedAt, start);
      verify(() => api.search('pasta')).called(1);
    });

    test('a stale cache emits first, then the refreshed data', () async {
      stubSearch('pasta');
      await repository.search('pasta').drain<void>();
      now = start.add(CachePolicy.lists);

      final emitted = await values(repository.search('pasta'));

      expect(emitted.map((c) => c.isRefreshing), [true, false]);
      expect(emitted.map((c) => c.fetchedAt), [start, now]);
    });

    test('forceRefresh revalidates a fresh cache', () async {
      stubSearch('pasta');
      await repository.search('pasta').drain<void>();

      final emitted = await values(
        repository.search('pasta', forceRefresh: true),
      );

      expect(emitted, hasLength(2));
      verify(() => api.search('pasta')).called(2);
    });

    test('a failed refresh keeps the cache and reports why', () async {
      stubSearch('pasta');
      await repository.search('pasta').drain<void>();
      now = start.add(const Duration(days: 1));
      when(() => api.search('pasta')).thenThrow(const NetworkFailure());

      final emitted = await values(repository.search('pasta'));

      expect(emitted.last.data, hasLength(1));
      expect(emitted.last.fetchedAt, start);
      expect(emitted.last.refreshFailure, isA<NetworkFailure>());
    });

    test('offline, an unseen query falls back to the local library', () async {
      stubSearch('');
      await repository.search('').drain<void>();
      when(() => api.search('pas')).thenThrow(const NetworkFailure());

      final emitted = await values(repository.search('pas'));

      expect(emitted.single.data.single.name, 'Pasta');
      expect(emitted.single.fetchedAt, isNull);
      expect(emitted.single.refreshFailure, isA<NetworkFailure>());
    });

    test('offline with nothing local ends in Err', () async {
      when(() => api.search(any())).thenThrow(const NetworkFailure());

      final emitted = await repository.search('pas').toList();

      expect(emitted.single, isA<Err<Cached<Object?>>>());
    });
  });

  group('byCategory', () {
    test('fills in the category the endpoint omits', () async {
      when(() => api.byCategory('Seafood')).thenAnswer(
        (_) async => [
          MealDto.fromJson({
            'idMeal': '5',
            'strMeal': 'Fish',
            'strMealThumb': 'u',
          }),
        ],
      );

      final emitted = await values(repository.byCategory('Seafood'));

      expect(emitted.single.data.single.category, 'Seafood');
    });

    test('offline, falls back to cached meals in that category', () async {
      await cache.saveQuery(searchKey(''), [pasta, curry], start);
      when(() => api.byCategory(any())).thenThrow(const ServerFailure(500));

      final emitted = await values(repository.byCategory('Chicken'));
      expect(emitted.single.data.single.id, '2');

      final empty = await repository.byCategory('Vegan').toList();
      expect(empty.single, isA<Err<Cached<Object?>>>());
    });
  });

  test('categories are cached', () async {
    when(() => api.categories()).thenAnswer((_) async => ['Beef', 'Pasta']);

    expect((await values(repository.categories())).single.data, [
      'Beef',
      'Pasta',
    ]);
    expect((await values(repository.categories())).single.data, [
      'Beef',
      'Pasta',
    ]);
    verify(() => api.categories()).called(1);
  });

  test('a meal is cached with its ingredients for a day', () async {
    when(
      () => api.lookup('1'),
    ).thenAnswer((_) async => MealDto.fromJson(mealJson()));

    final first = await values(repository.meal('1'));
    expect(first.single.data.ingredients, hasLength(2));

    now = start.add(const Duration(hours: 23));
    final second = await values(repository.meal('1'));
    expect(second.single.data.ingredients, hasLength(2));
    verify(() => api.lookup('1')).called(1);
  });

  test('an unknown meal ends in Err', () async {
    when(() => api.lookup(any())).thenThrow(const NotFoundFailure());

    final emitted = await repository.meal('x').toList();

    expect((emitted.single as Err).failure, isA<NotFoundFailure>());
  });
}
