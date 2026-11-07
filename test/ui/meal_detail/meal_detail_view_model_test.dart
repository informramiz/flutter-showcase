import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/core/result/result.dart';
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
    Map<String, Object> prefs = const {},
  }) async {
    container = await makeContainer(repository, prefs: prefs);
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
    when(() => repository.meal(any())).thenAnswer((_) async {
      calls++;
      return calls == 1
          ? const Err(NotFoundFailure())
          : const Success(pastaDetail);
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
    await start(
      prefs: {
        'favourites_v1': '[{"id":"1","name":"Pasta","thumbnailUrl":"u"}]',
      },
    );
    expect(state().isFavourite, isTrue);
  });
}
