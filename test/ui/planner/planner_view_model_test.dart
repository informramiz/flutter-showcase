import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_showcase/domain/repositories/planner_repository.dart';
import 'package:flutter_showcase/ui/planner/planner_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

PlannedMeal entry(int id, Meal meal, int position, {PlanDay? day}) =>
    PlannedMeal(
      entryId: id,
      day: day ?? PlanDay.monday,
      slot: MealSlot.dinner,
      position: position,
      meal: meal,
    );

class _BrokenPlanner extends FakePlannerRepository {
  @override
  Stream<List<PlannedMeal>> watchPlan() => Stream.error(StateError('disk'));
}

void main() {
  final first = entry(1, pasta, 0);
  final second = entry(2, curry, 1);

  Future<(ProviderContainer, FakePlannerRepository)> setUpVm(
    List<PlannedMeal> plan,
  ) async {
    final fake = FakePlannerRepository(plan);
    final container = await makeContainer(
      stubbedRepository(),
      plannerRepository: fake,
    );
    container.listen(plannerViewModelProvider, (_, _) {});
    await pumpEventQueue();
    return (container, fake);
  }

  test('mirrors the plan stream', () async {
    final (container, _) = await setUpVm([first, second]);

    expect(container.read(plannerViewModelProvider).plan.value, [
      first,
      second,
    ]);
  });

  test('surfaces a broken plan stream as an error', () async {
    final PlannerRepository broken = _BrokenPlanner();
    final container = await makeContainer(
      stubbedRepository(),
      plannerRepository: broken,
    );
    container.listen(plannerViewModelProvider, (_, _) {});
    await pumpEventQueue();

    expect(container.read(plannerViewModelProvider).plan.hasError, isTrue);
  });

  test('move up and down stay inside the slot', () async {
    final (container, fake) = await setUpVm([first, second]);
    final vm = container.read(plannerViewModelProvider.notifier);

    await vm.moveUp(first);
    await vm.moveDown(second);
    await vm.moveDown(first);
    await vm.moveUp(second);

    expect(vm.isLastInSlot(second), isTrue);
    expect(vm.isLastInSlot(first), isFalse);
    expect(fake.calls, [
      'move 1 monday dinner 1',
      'move 2 monday dinner 0',
    ]);
  });

  test('moveTo appends to the target slot and ignores the same slot', () async {
    final friday = entry(3, pasta, 0, day: PlanDay.friday);
    final (container, fake) = await setUpVm([first, second, friday]);
    final vm = container.read(plannerViewModelProvider.notifier);

    await vm.moveTo(first, PlanDay.monday, MealSlot.dinner);
    await vm.moveTo(first, PlanDay.friday, MealSlot.dinner);

    expect(fake.calls, ['move 1 friday dinner 1']);
  });

  test('remove deletes the entry', () async {
    final (container, fake) = await setUpVm([first, second]);

    await container.read(plannerViewModelProvider.notifier).remove(first);

    expect(fake.calls, ['remove 1']);
    expect(container.read(plannerViewModelProvider).plan.value, [second]);
  });
}
