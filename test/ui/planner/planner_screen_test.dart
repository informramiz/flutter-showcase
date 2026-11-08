import 'package:flutter/material.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

void main() {
  PlannedMeal entry(int id, int position, {PlanDay day = PlanDay.monday}) =>
      PlannedMeal(
        entryId: id,
        day: day,
        slot: MealSlot.dinner,
        position: position,
        meal: id.isOdd ? pastaDetail : curry,
      );

  Future<void> openPlanner(
    WidgetTester tester,
    FakePlannerRepository fake, {
    FakeCookReminderService? reminders,
  }) async {
    await pumpApp(
      tester,
      stubbedRepository(),
      plannerRepository: fake,
      cookReminderService: reminders,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.plannerTab).last);
    await tester.pumpAndSettle();
  }

  Future<void> chooseFromMenu(WidgetTester tester, int id, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey('plan-entry-$id')),
        matching: find.byIcon(Icons.adaptive.more),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('an empty plan explains how to add meals', (tester) async {
    await openPlanner(tester, FakePlannerRepository());

    expect(find.text(l10n.emptyPlan), findsOneWidget);
    expect(find.text(l10n.emptyPlanHint), findsOneWidget);
  });

  testWidgets('entries are grouped under their day', (tester) async {
    await openPlanner(
      tester,
      FakePlannerRepository([entry(1, 0), entry(2, 0, day: PlanDay.friday)]),
    );

    expect(find.text(l10n.monday), findsOneWidget);
    expect(find.text(l10n.friday), findsOneWidget);
    expect(find.text(l10n.tuesday), findsNothing);
    expect(find.text('Spaghetti Bolognese'), findsOneWidget);
    expect(find.text(l10n.dinner), findsNWidgets(2));
  });

  testWidgets('the entry menu moves and removes', (tester) async {
    final fake = FakePlannerRepository([entry(1, 0), entry(2, 1)]);
    await openPlanner(tester, fake);

    await chooseFromMenu(tester, 1, l10n.moveDown);
    await chooseFromMenu(tester, 2, l10n.moveUp);
    await chooseFromMenu(tester, 1, l10n.moveTo);
    await tester.tap(find.text(l10n.sunday));
    await tester.tap(find.text(l10n.lunch));
    await tester.tap(find.text(l10n.add));
    await tester.pumpAndSettle();
    await chooseFromMenu(tester, 2, l10n.remove);

    expect(fake.calls, [
      'move 1 monday dinner 1',
      'move 2 monday dinner 0',
      'move 1 sunday lunch 0',
      'remove 2',
    ]);
    expect(find.text('Chicken Curry'), findsNothing);
  });

  testWidgets('the cart opens the shopping list', (tester) async {
    await openPlanner(tester, FakePlannerRepository([entry(1, 0)]));

    await tester.tap(find.byTooltip(l10n.shoppingList));
    await tester.pumpAndSettle();

    expect(find.text('Spaghetti · 200 g'), findsOneWidget);
    expect(find.text('Tomato · 3'), findsOneWidget);
  });

  testWidgets('tapping an entry opens the meal', (tester) async {
    await openPlanner(tester, FakePlannerRepository([entry(1, 0)]));

    await tester.tap(find.text('Spaghetti Bolognese'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.ingredients), findsOneWidget);
  });

  testWidgets('the menu toggles a cook reminder', (tester) async {
    final fake = FakePlannerRepository([entry(1, 0)]);
    final reminders = FakeCookReminderService();
    await openPlanner(tester, fake, reminders: reminders);

    await chooseFromMenu(tester, 1, l10n.cookReminder);
    expect(find.byKey(const ValueKey('reminder-on-1')), findsOneWidget);
    await chooseFromMenu(tester, 1, l10n.cookReminder);

    expect(find.byKey(const ValueKey('reminder-on-1')), findsNothing);
    expect(fake.calls, ['reminder 1 true', 'reminder 1 false']);
    expect(reminders.calls.first, 'permission');
    expect(reminders.calls.last, 'cancel 1');
  });

  testWidgets('a refused permission explains why', (tester) async {
    await openPlanner(
      tester,
      FakePlannerRepository([entry(1, 0)]),
      reminders: FakeCookReminderService(granted: false),
    );

    await chooseFromMenu(tester, 1, l10n.cookReminder);

    expect(find.text(l10n.reminderDenied), findsOneWidget);
  });

  testWidgets('no reminder option where reminders are unsupported', (
    tester,
  ) async {
    await openPlanner(
      tester,
      FakePlannerRepository([entry(1, 0)]),
      reminders: FakeCookReminderService(isSupported: false),
    );

    await tester.tap(find.byIcon(Icons.adaptive.more));
    await tester.pumpAndSettle();

    expect(find.text(l10n.cookReminder), findsNothing);
  });
}
