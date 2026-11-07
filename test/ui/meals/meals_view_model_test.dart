import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_showcase/ui/meals/meals_ui_state.dart';
import 'package:flutter_showcase/ui/meals/meals_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

void main() {
  late MockMealRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = stubbedRepository();
  });

  Future<MealsViewModel> start({Map<String, Object> prefs = const {}}) async {
    container = (await makeContainer(repository, prefs: prefs))
      ..listen(mealsViewModelProvider, (_, _) {});
    return container.read(mealsViewModelProvider.notifier);
  }

  MealsUiState state() => container.read(mealsViewModelProvider);

  Future<void> settle([Duration extra = Duration.zero]) =>
      Future<void>.delayed(extra + const Duration(milliseconds: 20));

  test('starts loading, then publishes meals and categories', () async {
    await start();
    expect(state().meals, isA<AsyncLoading<Object?>>());
    expect(state().categories, isA<AsyncLoading<Object?>>());

    await settle();

    expect(state().meals.value, [pasta, curry]);
    expect(state().categories.value, ['Pasta', 'Chicken']);
    verify(() => repository.search('')).called(1);
  });

  test('a category switches to the filter endpoint', () async {
    final viewModel = await start();
    await settle();

    viewModel.selectCategory('Pasta');
    expect(state().selectedCategory, 'Pasta');
    expect(state().meals, isA<AsyncLoading<Object?>>());
    await settle();

    verify(() => repository.byCategory('Pasta')).called(1);
    viewModel.selectCategory(null);
    expect(state().selectedCategory, isNull);
  });

  test(
    'typing is debounced: only the last query hits the repository',
    () async {
      final viewModel = await start();
      await settle();

      viewModel.search('s');
      await settle(const Duration(milliseconds: 100));
      viewModel.search('sp');
      await settle(const Duration(milliseconds: 100));
      viewModel.search('spa');
      expect(state().query, 'spa');
      await settle(searchDebounce);

      verify(() => repository.search('spa')).called(1);
      verifyNever(() => repository.search('s'));
      verifyNever(() => repository.search('sp'));
      expect(state().meals.value, [pasta, curry]);
    },
  );

  test('a search narrows by the selected category on the client', () async {
    final viewModel = await start();
    await settle();

    viewModel
      ..search('c')
      ..selectCategory('Chicken');
    await settle(searchDebounce);

    expect(state().meals.value, [curry]);
    verifyNever(() => repository.byCategory(any()));
  });

  test('a failure becomes an error state and retry recovers', () async {
    var calls = 0;
    when(() => repository.search(any())).thenAnswer((_) async {
      calls++;
      return calls == 1
          ? const Err(ServerFailure(500))
          : const Success([pasta]);
    });
    final viewModel = await start();
    await settle();
    expect(state().meals.error, isA<ServerFailure>());

    viewModel.retry();
    await settle();

    expect(state().meals.value, [pasta]);
  });

  test('categories that fail to load leave the list usable', () async {
    when(
      repository.categories,
    ).thenAnswer((_) async => const Err(NetworkFailure()));
    await start();
    await settle();

    expect(state().categories.hasError, isTrue);
    expect(state().meals.value, [pasta, curry]);
  });

  test('favouriteIds follow the repository, and toggling persists', () async {
    final viewModel = await start();
    await settle();
    expect(state().favouriteIds, isEmpty);

    await viewModel.toggleFavourite(pasta);
    expect(state().favouriteIds, {'1'});

    await viewModel.toggleFavourite(pasta);
    expect(state().favouriteIds, isEmpty);
  });

  test('restores favourite ids saved by a previous run', () async {
    await start(
      prefs: {
        'favourites_v1':
            '[{"id":"2","name":"Chicken Curry","thumbnailUrl":"u"}]',
      },
    );
    expect(state().favouriteIds, {'2'});
    expect(
      container.read(favouritesRepositoryProvider).favourites,
      hasLength(1),
    );
  });
}
