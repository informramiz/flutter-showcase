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

const ReminderText text = (title: 'Cook', body: 'Pasta next');

void main() {
  final first = entry(1, pasta, 0);
  final second = entry(2, curry, 1);
  late FakeCookReminderService reminders;

  Future<(ProviderContainer, FakePlannerRepository)> setUpVm(
    List<PlannedMeal> plan, {
    bool granted = true,
  }) async {
    final fake = FakePlannerRepository(plan);
    reminders = FakeCookReminderService(granted: granted);
    final container = await makeContainer(
      stubbedRepository(),
      plannerRepository: fake,
      cookReminderService: reminders,
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

    await vm.moveTo(first, PlanDay.monday, MealSlot.dinner, reminder: text);
    await vm.moveTo(first, PlanDay.friday, MealSlot.dinner, reminder: text);

    expect(fake.calls, ['move 1 friday dinner 1']);
    expect(reminders.calls, isEmpty);
  });

  test('remove deletes the entry', () async {
    final (container, fake) = await setUpVm([first, second]);

    await container.read(plannerViewModelProvider.notifier).remove(first);

    expect(fake.calls, ['remove 1']);
    expect(container.read(plannerViewModelProvider).plan.value, [second]);
  });

  group('cook reminders', () {
    // testNow is Sunday 2026-11-08 12:00; Monday dinner is at 19:00.
    final mondayReminder = DateTime(2026, 11, 9, 18);

    test('turning one on asks permission, schedules and saves', () async {
      final (container, fake) = await setUpVm([first]);
      final vm = container.read(plannerViewModelProvider.notifier);

      expect(
        container.read(plannerViewModelProvider).remindersSupported,
        isTrue,
      );
      expect(await vm.setReminder(first, enabled: true, text: text), isTrue);

      expect(reminders.calls, [
        'permission',
        'schedule 1 $mondayReminder /meal/${pasta.id} Pasta next',
      ]);
      expect(fake.calls, ['reminder 1 true']);
    });

    test('a refused permission changes nothing', () async {
      final (container, fake) = await setUpVm([first], granted: false);
      final vm = container.read(plannerViewModelProvider.notifier);

      expect(await vm.setReminder(first, enabled: true, text: text), isFalse);

      expect(reminders.calls, ['permission']);
      expect(fake.calls, isEmpty);
    });

    test('turning one off cancels it', () async {
      final on = first.copyWith(reminderEnabled: true);
      final (container, fake) = await setUpVm([on]);

      await container
          .read(plannerViewModelProvider.notifier)
          .setReminder(on, enabled: false, text: text);

      expect(reminders.calls, ['cancel 1']);
      expect(fake.calls, ['reminder 1 false']);
    });

    test('an enabled reminder moves and is removed with its entry', () async {
      final on = first.copyWith(reminderEnabled: true);
      final (container, _) = await setUpVm([on]);
      final vm = container.read(plannerViewModelProvider.notifier);

      await vm.moveTo(on, PlanDay.tuesday, MealSlot.lunch, reminder: text);
      await vm.remove(on);

      final tuesdayLunch = DateTime(2026, 11, 10, 12);
      expect(reminders.calls, [
        'schedule 1 $tuesdayLunch /meal/${pasta.id} Pasta next',
        'cancel 1',
      ]);
    });
  });
}
