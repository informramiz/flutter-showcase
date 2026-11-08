import 'package:flutter_showcase/data/database/app_database.dart';
import 'package:flutter_showcase/data/repositories/planner_repository_impl.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/database.dart';
import '../../helpers/fixtures.dart';

const soup = Meal(id: '3', name: 'Soup', thumbnailUrl: 'https://e.com/3.jpg');

void main() {
  late AppDatabase database;
  late PlannerRepositoryImpl repository;

  setUp(() {
    database = memoryDatabase();
    repository = PlannerRepositoryImpl(database.plannerDao);
  });

  Future<List<PlannedMeal>> plan() => repository.watchPlan().first;

  String layout(List<PlannedMeal> entries) => [
    for (final e in entries)
      '${e.day.name}/${e.slot.name}/${e.position}:${e.meal.id}',
  ].join(' ');

  test('add appends to the end of its day and slot', () async {
    await repository.add(pasta, PlanDay.monday, MealSlot.dinner);
    await repository.add(curry, PlanDay.monday, MealSlot.dinner);
    await repository.add(soup, PlanDay.monday, MealSlot.lunch);

    expect(
      layout(await plan()),
      'monday/lunch/0:3 monday/dinner/0:1 monday/dinner/1:2',
    );
  });

  test('move reorders within a slot', () async {
    await repository.add(pasta, PlanDay.monday, MealSlot.dinner);
    await repository.add(curry, PlanDay.monday, MealSlot.dinner);
    final soupId = await repository.add(soup, PlanDay.monday, MealSlot.dinner);

    await repository.move(soupId, PlanDay.monday, MealSlot.dinner, 0);

    expect(
      layout(await plan()),
      'monday/dinner/0:3 monday/dinner/1:1 monday/dinner/2:2',
    );
  });

  test('move to another day closes the gap it leaves', () async {
    final pastaId = await repository.add(
      pasta,
      PlanDay.monday,
      MealSlot.dinner,
    );
    await repository.add(curry, PlanDay.monday, MealSlot.dinner);
    await repository.add(soup, PlanDay.friday, MealSlot.lunch);

    await repository.move(pastaId, PlanDay.friday, MealSlot.lunch, 99);

    expect(
      layout(await plan()),
      'monday/dinner/0:2 friday/lunch/0:3 friday/lunch/1:1',
    );
  });

  test('remove renumbers the rest of the slot', () async {
    final pastaId = await repository.add(
      pasta,
      PlanDay.sunday,
      MealSlot.breakfast,
    );
    await repository.add(curry, PlanDay.sunday, MealSlot.breakfast);

    await repository.remove(pastaId);

    expect(layout(await plan()), 'sunday/breakfast/0:2');
  });

  test('moving or removing an unknown entry does nothing', () async {
    await repository.add(pasta, PlanDay.monday, MealSlot.dinner);

    await repository.move(42, PlanDay.friday, MealSlot.lunch, 0);
    await repository.remove(42);

    expect(layout(await plan()), 'monday/dinner/0:1');
  });

  test('the plan carries ingredients and re-emits when a recipe is cached '
      'later', () async {
    await repository.add(pasta, PlanDay.monday, MealSlot.dinner);
    final emissions = <List<PlannedMeal>>[];
    final subscription = repository.watchPlan().listen(emissions.add);
    await pumpEventQueue();
    expect(emissions.last.single.meal.ingredients, isEmpty);

    await database.mealCacheDao.saveMealDetail(pastaDetail, DateTime(2026));
    await pumpEventQueue();

    expect(
      emissions.last.single.meal.ingredients,
      pastaDetail.ingredients,
    );
    await subscription.cancel();
  });

  test('a meal planned twice keeps its own ingredients per entry', () async {
    await database.mealCacheDao.saveMealDetail(pastaDetail, DateTime(2026));
    await repository.add(pasta, PlanDay.monday, MealSlot.dinner);
    await repository.add(pasta, PlanDay.tuesday, MealSlot.dinner);

    final entries = await plan();
    expect(entries, hasLength(2));
    expect(entries.every((e) => e.meal.ingredients.length == 2), isTrue);
  });

  test('setReminder flips the flag', () async {
    final id = await repository.add(pasta, PlanDay.monday, MealSlot.dinner);

    await repository.setReminder(id, enabled: true);
    expect((await plan()).single.reminderEnabled, isTrue);

    await repository.setReminder(id, enabled: false);
    expect((await plan()).single.reminderEnabled, isFalse);
  });

  test('checked keys persist, ignore duplicates and clear together', () async {
    await repository.setChecked('egg', checked: true);
    await repository.setChecked('egg', checked: true);
    await repository.setChecked('salt', checked: true);
    expect(await repository.watchCheckedKeys().first, {'egg', 'salt'});

    await repository.setChecked('egg', checked: false);
    expect(await repository.watchCheckedKeys().first, {'salt'});

    await repository.uncheckAll();
    expect(await repository.watchCheckedKeys().first, isEmpty);
  });
}
