import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/repositories/favourites_repository.dart';
import 'package:flutter_showcase/ui/favourites/favourites_ui_state.dart';
import 'package:flutter_showcase/ui/favourites/favourites_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

class _BrokenFavourites implements FavouritesRepository {
  @override
  Stream<List<Meal>> watchFavourites() => Stream.error(StateError('disk'));

  @override
  Future<void> toggle(Meal meal) async {}
}

void main() {
  late ProviderContainer container;

  Future<FavouritesViewModel> start({
    List<Meal> favourites = const [],
    FavouritesRepository? repository,
  }) async {
    container = (await makeContainer(
      MockMealRepository(),
      favourites: favourites,
      favouritesRepository: repository,
    ))..listen(favouritesViewModelProvider, (_, _) {});
    final viewModel = container.read(favouritesViewModelProvider.notifier);
    await pumpEventQueue();
    return viewModel;
  }

  FavouritesUiState state() => container.read(favouritesViewModelProvider);
  List<String> ids() => [for (final m in state().meals.value!) m.id];

  test('starts empty', () async {
    await start();
    expect(state().meals.value, isEmpty);
  });

  test('toggleFavourite adds newest first, then removes', () async {
    final viewModel = await start();

    await viewModel.toggleFavourite(pasta);
    await viewModel.toggleFavourite(curry);
    expect(ids(), ['2', '1']);

    await viewModel.toggleFavourite(pasta);
    expect(ids(), ['2']);
  });

  test('shows favourites already saved', () async {
    await start(favourites: [curry, pasta]);
    expect(ids(), ['2', '1']);
  });

  test('a storage error becomes an error state', () async {
    await start(repository: _BrokenFavourites());
    expect(state().meals.hasError, isTrue);
  });
}
