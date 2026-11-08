import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/meal_collection.dart';
import 'package:flutter_showcase/domain/services/collection_name.dart';
import 'package:flutter_showcase/ui/collections/collections_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

const dinners = MealCollection(id: 1, name: 'Dinners');
const lunches = MealCollection(id: 2, name: 'Lunches');

class _BrokenCollections extends FakeCollectionsRepository {
  @override
  Stream<List<MealCollection>> watchCollections() =>
      Stream.error(StateError('disk'));
}

void main() {
  Future<(ProviderContainer, FakeCollectionsRepository)> setUpContainer([
    FakeCollectionsRepository? fake,
  ]) async {
    final repository =
        fake ??
        FakeCollectionsRepository({
          dinners: [pasta],
          lunches: const [],
        });
    final container = await makeContainer(
      stubbedRepository(),
      collectionsRepository: repository,
    );
    return (container, repository);
  }

  group('CollectionsViewModel', () {
    test('mirrors the collections with counts', () async {
      final (container, _) = await setUpContainer();
      container.listen(collectionsViewModelProvider, (_, _) {});
      await pumpEventQueue();

      expect(
        container.read(collectionsViewModelProvider).collections.value,
        [dinners.copyWith(mealCount: 1), lunches],
      );
    });

    test('surfaces a stream error', () async {
      final (container, _) = await setUpContainer(_BrokenCollections());
      container.listen(collectionsViewModelProvider, (_, _) {});
      await pumpEventQueue();

      expect(
        container.read(collectionsViewModelProvider).collections.hasError,
        isTrue,
      );
    });

    test(
      'validate rejects duplicates but lets a rename keep its name',
      () async {
        final (container, _) = await setUpContainer();
        container.listen(collectionsViewModelProvider, (_, _) {});
        await pumpEventQueue();
        final viewModel = container.read(collectionsViewModelProvider.notifier);

        expect(viewModel.validate('dinners'), CollectionNameError.duplicate);
        expect(viewModel.validate('Dinners', renaming: 1), isNull);
        expect(viewModel.validate('  '), CollectionNameError.empty);
        expect(viewModel.validate('Snacks'), isNull);
      },
    );

    test('create, rename and delete reach the repository', () async {
      final (container, fake) = await setUpContainer();
      final viewModel = container.read(collectionsViewModelProvider.notifier);

      final id = await viewModel.create('Snacks');
      await viewModel.rename(1, 'Suppers');
      await viewModel.delete(2);

      expect(
        (await fake.watchCollections().first).map((c) => '${c.id}:${c.name}'),
        ['$id:Snacks', '1:Suppers'],
      );
    });
  });

  group('CollectionDetailViewModel', () {
    test('shows the collection and its meals; remove updates', () async {
      final (container, _) = await setUpContainer();
      final provider = collectionDetailViewModelProvider(1);
      container.listen(provider, (_, _) {});
      await pumpEventQueue();

      expect(container.read(provider).collection?.name, 'Dinners');
      expect(container.read(provider).meals.value, [pasta]);

      await container.read(provider.notifier).remove(pasta);
      await pumpEventQueue();
      expect(container.read(provider).meals.value, isEmpty);
    });

    test('an unknown id loads as missing', () async {
      final (container, _) = await setUpContainer();
      final provider = collectionDetailViewModelProvider(99);
      container.listen(provider, (_, _) {});
      await pumpEventQueue();

      expect(container.read(provider).collectionLoaded, isTrue);
      expect(container.read(provider).collection, isNull);
    });
  });

  group('SaveToCollectionViewModel', () {
    test('tracks membership and toggles it', () async {
      final (container, _) = await setUpContainer();
      final provider = saveToCollectionViewModelProvider(pasta.id);
      container.listen(provider, (_, _) {});
      await pumpEventQueue();
      expect(container.read(provider).selectedIds, {1});

      final viewModel = container.read(provider.notifier);
      await viewModel.toggle(dinners, pasta);
      await viewModel.toggle(lunches, pasta);
      await pumpEventQueue();

      expect(container.read(provider).selectedIds, {2});
    });

    test('createWith makes a collection holding the meal', () async {
      final (container, fake) = await setUpContainer();
      final provider = saveToCollectionViewModelProvider(curry.id);
      container.listen(provider, (_, _) {});
      await pumpEventQueue();

      await container.read(provider.notifier).createWith('Spicy', curry);
      await pumpEventQueue();

      expect(container.read(provider).selectedIds, {3});
      expect(await fake.watchMeals(3).first, [curry]);
    });
  });
}
