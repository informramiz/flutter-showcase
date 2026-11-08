import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_showcase/ui/shopping/shopping_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

class _BrokenChecks extends FakePlannerRepository {
  @override
  Stream<Set<String>> watchCheckedKeys() => Stream.error(StateError('disk'));
}

void main() {
  const planned = PlannedMeal(
    entryId: 1,
    day: PlanDay.monday,
    slot: MealSlot.dinner,
    position: 0,
    meal: pastaDetail,
  );

  Future<ProviderContainer> setUpVm(FakePlannerRepository fake) async {
    final container = await makeContainer(
      stubbedRepository(),
      plannerRepository: fake,
    );
    container.listen(shoppingListViewModelProvider, (_, _) {});
    await pumpEventQueue();
    return container;
  }

  test('builds the list from the plan with stored ticks', () async {
    final container = await setUpVm(
      FakePlannerRepository([planned, planned], {'tomato'}),
    );

    final items = container.read(shoppingListViewModelProvider).items.value!;
    expect(items.map((i) => (i.key, i.checked)), [
      ('spaghetti', false),
      ('tomato', true),
    ]);
  });

  test('toggle and uncheckAll write through and rebuild', () async {
    final container = await setUpVm(FakePlannerRepository([planned]));
    final vm = container.read(shoppingListViewModelProvider.notifier);
    List<bool> checks() => [
      for (final i
          in container.read(shoppingListViewModelProvider).items.value!)
        i.checked,
    ];

    await vm.toggle(
      container.read(shoppingListViewModelProvider).items.value!.first,
    );
    expect(checks(), [true, false]);

    await vm.uncheckAll();
    expect(checks(), [false, false]);
  });

  test('a broken stream shows an error', () async {
    final container = await setUpVm(_BrokenChecks());

    expect(
      container.read(shoppingListViewModelProvider).items.hasError,
      isTrue,
    );
  });
}
