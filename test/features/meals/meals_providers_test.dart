import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/features/meals/presentation/meals_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

void main() {
  late MockMealRepository repository;

  setUp(() {
    repository = MockMealRepository();
    when(() => repository.search(any())).thenAnswer(
      (_) async => const Success([pasta, curry]),
    );
  });

  Future<void> settle() =>
      Future<void>.delayed(searchDebounce + const Duration(milliseconds: 50));

  test('loads the default list when nothing is selected', () async {
    final container = await makeContainer(repository);

    final meals = await container.read(mealsProvider.future);

    expect(meals, [pasta, curry]);
    verify(() => repository.search('')).called(1);
  });

  test('a category switches to the filter endpoint', () async {
    when(() => repository.byCategory('Pasta')).thenAnswer(
      (_) async => const Success([pasta]),
    );
    final container = await makeContainer(repository);
    container.read(selectedCategoryProvider.notifier).select('Pasta');

    expect(await container.read(mealsProvider.future), [pasta]);
    verifyNever(() => repository.search(any()));
  });

  test(
    'typing is debounced: only the last query reaches the repository',
    () async {
      final container = await makeContainer(repository);
      final sub = container.listen(mealsProvider, (_, _) {});
      addTearDown(sub.close);
      final search = container.read(searchQueryProvider.notifier)..set('s');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      search.set('sp');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      search.set('spa');
      await settle();

      verify(() => repository.search('spa')).called(1);
      verifyNever(() => repository.search('s'));
      verifyNever(() => repository.search('sp'));
      expect(await container.read(mealsProvider.future), [pasta, curry]);
    },
  );

  test('a search narrows by the selected category on the client', () async {
    final container = await makeContainer(repository);
    final sub = container.listen(mealsProvider, (_, _) {});
    addTearDown(sub.close);
    container.read(selectedCategoryProvider.notifier).select('Chicken');
    container.read(searchQueryProvider.notifier).set('c');
    await settle();

    expect(await container.read(mealsProvider.future), [curry]);
  });

  test('a failing repository surfaces the failure in AsyncError', () async {
    when(() => repository.search(any())).thenAnswer(
      (_) async => const Err(NetworkFailure()),
    );
    final container = await makeContainer(repository);
    final sub = container.listen(mealsProvider, (_, _) {});
    addTearDown(sub.close);

    await expectLater(
      container.read(mealsProvider.future),
      throwsA(isA<NetworkFailure>()),
    );
    expect(container.read(mealsProvider).hasError, isTrue);
  });

  test('retry after a failure loads data (invalidate)', () async {
    var calls = 0;
    when(() => repository.search(any())).thenAnswer((_) async {
      calls++;
      return calls == 1
          ? const Err(ServerFailure(500))
          : const Success([pasta]);
    });
    final container = await makeContainer(repository);
    final sub = container.listen(mealsProvider, (_, _) {});
    addTearDown(sub.close);
    await expectLater(
      container.read(mealsProvider.future),
      throwsA(isA<ServerFailure>()),
    );

    container.invalidate(mealsProvider);

    expect(await container.read(mealsProvider.future), [pasta]);
  });

  test('categories and detail providers unwrap their Results', () async {
    when(() => repository.categories()).thenAnswer(
      (_) async => const Success(['Beef']),
    );
    when(() => repository.meal('1')).thenAnswer(
      (_) async => const Success(pastaDetail),
    );
    final container = await makeContainer(repository);

    expect(await container.read(categoriesProvider.future), ['Beef']);
    expect(await container.read(mealDetailProvider('1').future), pastaDetail);
  });
}
