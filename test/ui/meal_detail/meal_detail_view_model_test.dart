import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/domain/models/cached.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/ui/meal_detail/meal_detail_ui_state.dart';
import 'package:flutter_showcase/ui/meal_detail/meal_detail_view_model.dart';
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

  Future<MealDetailViewModel> start({
    List<Meal> favourites = const [],
  }) async {
    container = await makeContainer(repository, favourites: favourites);
    final provider = mealDetailViewModelProvider('1');
    container.listen(provider, (_, _) {});
    return container.read(provider.notifier);
  }

  MealDetailUiState state() => container.read(mealDetailViewModelProvider('1'));

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('loads the meal for its id', () async {
    await start();
    expect(state().meal, isA<AsyncLoading<Object?>>());

    await settle();

    expect(state().meal.value, pastaDetail);
    expect(state().isFavourite, isFalse);
    verify(() => repository.meal('1')).called(1);
  });

  test('a failure becomes an error state and retry recovers', () async {
    var calls = 0;
    when(() => repository.meal(any(), forceRefresh: anyForce)).thenAnswer((_) {
      calls++;
      return calls == 1
          ? failed<Meal>(const NotFoundFailure())
          : fresh(pastaDetail);
    });
    final viewModel = await start();
    await settle();
    expect(state().meal.error, isA<NotFoundFailure>());

    viewModel.retry();
    expect(state().meal, isA<AsyncLoading<Object?>>());
    await settle();

    expect(state().meal.value, pastaDetail);
  });

  test('toggleFavourite flips the flag and is a no-op before load', () async {
    final viewModel = await start();
    await viewModel.toggleFavourite();
    expect(state().isFavourite, isFalse);

    await settle();
    await viewModel.toggleFavourite();
    expect(state().isFavourite, isTrue);

    await viewModel.toggleFavourite();
    expect(state().isFavourite, isFalse);
  });

  test('starts as favourite when saved by a previous run', () async {
    await start(favourites: [pasta]);
    await settle();
    expect(state().isFavourite, isTrue);
  });

  test('refresh skips the cache and records freshness', () async {
    final viewModel = await start();
    await settle();
    final at = testNow.subtract(const Duration(hours: 3));
    when(() => repository.meal('1', forceRefresh: true)).thenAnswer(
      (_) => Stream.value(
        Success(
          Cached(
            pastaDetail,
            fetchedAt: at,
            refreshFailure: const NetworkFailure(),
          ),
        ),
      ),
    );

    await viewModel.refresh();

    expect(state().freshness.fetchedAt, at);
    expect(state().freshness.refreshFailure, isA<NetworkFailure>());
    expect(state().meal.value, pastaDetail);
  });
}
