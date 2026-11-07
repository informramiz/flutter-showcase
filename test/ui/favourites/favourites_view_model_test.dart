import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/ui/favourites/favourites_ui_state.dart';
import 'package:flutter_showcase/ui/favourites/favourites_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

void main() {
  late ProviderContainer container;

  Future<FavouritesViewModel> start({
    Map<String, Object> prefs = const {},
  }) async {
    container = (await makeContainer(MockMealRepository(), prefs: prefs))
      ..listen(favouritesViewModelProvider, (_, _) {});
    return container.read(favouritesViewModelProvider.notifier);
  }

  FavouritesUiState state() => container.read(favouritesViewModelProvider);

  test('starts empty', () async {
    await start();
    expect(state().meals, isEmpty);
  });

  test('toggleFavourite adds newest first, then removes', () async {
    final viewModel = await start();

    await viewModel.toggleFavourite(pasta);
    await viewModel.toggleFavourite(curry);
    expect(state().meals.map((m) => m.id), ['2', '1']);

    await viewModel.toggleFavourite(pasta);
    expect(state().meals.map((m) => m.id), ['2']);
  });

  test('restores favourites saved by a previous run', () async {
    await start(
      prefs: {
        'favourites_v1': '[{"id":"1","name":"Pasta","thumbnailUrl":"u"}]',
      },
    );
    expect(state().meals.single.id, '1');
  });
}
