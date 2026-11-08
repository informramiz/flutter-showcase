import 'package:flutter/material.dart';
import 'package:flutter_showcase/domain/models/plan.dart';
import 'package:flutter_showcase/ui/shopping/shopping_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

void main() {
  const planned = PlannedMeal(
    entryId: 1,
    day: PlanDay.monday,
    slot: MealSlot.dinner,
    position: 0,
    meal: pastaDetail,
  );

  testWidgets('an empty plan has nothing to buy', (tester) async {
    await pumpScreen(tester, const ShoppingListScreen(), stubbedRepository());
    await tester.pump();

    expect(find.text(l10n.emptyShopping), findsOneWidget);
    expect(find.byTooltip(l10n.uncheckAll), findsNothing);
  });

  testWidgets('ticking an item persists and uncheck all clears it', (
    tester,
  ) async {
    final fake = FakePlannerRepository([planned, planned]);
    await pumpScreen(
      tester,
      const ShoppingListScreen(),
      stubbedRepository(),
      plannerRepository: fake,
    );
    await tester.pump();

    expect(find.text('Spaghetti · 400 g'), findsOneWidget);
    expect(find.text(l10n.usedIn('Spaghetti Bolognese')), findsNWidgets(2));

    await tester.tap(find.text('Tomato · 6'));
    await tester.pump();
    expect(await fake.watchCheckedKeys().first, {'tomato'});
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile).last).value,
      isTrue,
    );

    await tester.tap(find.byTooltip(l10n.uncheckAll));
    await tester.pump();
    expect(await fake.watchCheckedKeys().first, isEmpty);
  });
}
