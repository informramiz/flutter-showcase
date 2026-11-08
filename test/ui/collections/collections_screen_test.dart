import 'package:flutter/material.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/domain/models/meal_collection.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

const dinners = MealCollection(id: 1, name: 'Dinners');

void main() {
  Future<FakeCollectionsRepository> openCollections(
    WidgetTester tester, [
    Map<MealCollection, List<Meal>>? initial,
  ]) async {
    final fake = FakeCollectionsRepository(
      initial ??
          {
            dinners: [pasta],
          },
    );
    await pumpApp(tester, stubbedRepository(), collectionsRepository: fake);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.collectionsTab).last);
    await tester.pumpAndSettle();
    return fake;
  }

  Future<void> enterName(
    WidgetTester tester,
    String name,
    String confirm,
  ) async {
    await tester.enterText(
      find.byKey(const ValueKey('collection-name-field')),
      name,
    );
    await tester.tap(find.text(confirm));
    await tester.pumpAndSettle();
  }

  Future<void> chooseFromMenu(WidgetTester tester, String label) async {
    await tester.tap(find.byIcon(Icons.adaptive.more).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('no collections shows a hint', (tester) async {
    await openCollections(tester, {});

    expect(find.text(l10n.emptyCollections), findsOneWidget);
  });

  testWidgets('lists collections with meal counts', (tester) async {
    await openCollections(tester);

    expect(find.text('Dinners'), findsOneWidget);
    expect(find.text(l10n.mealCount(1)), findsOneWidget);
  });

  testWidgets('creating validates the name first', (tester) async {
    await openCollections(tester);
    await tester.tap(find.text(l10n.newCollection));
    await tester.pumpAndSettle();

    await enterName(tester, 'dinners', l10n.create);
    expect(find.text(l10n.nameDuplicate), findsOneWidget);

    await enterName(tester, 'Breakfast', l10n.create);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('cancel closes the dialog without creating', (tester) async {
    await openCollections(tester, {});
    await tester.tap(find.text(l10n.newCollection));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.emptyCollections), findsOneWidget);
  });

  testWidgets('rename from the menu', (tester) async {
    await openCollections(tester);
    await chooseFromMenu(tester, l10n.rename);
    await enterName(tester, 'Suppers', l10n.save);

    expect(find.text('Suppers'), findsOneWidget);
  });

  testWidgets('delete asks first', (tester) async {
    await openCollections(tester);
    await chooseFromMenu(tester, l10n.delete);
    expect(find.text(l10n.deleteCollection('Dinners')), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, l10n.delete));
    await tester.pumpAndSettle();

    expect(find.text(l10n.emptyCollections), findsOneWidget);
  });

  testWidgets('a collection page lists and removes its meals', (tester) async {
    await openCollections(tester);
    await tester.tap(find.text('Dinners'));
    await tester.pumpAndSettle();

    expect(find.text(pasta.name), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.removeFromCollection));
    await tester.pumpAndSettle();

    expect(find.text(l10n.emptyCollection), findsOneWidget);
  });

  testWidgets('deleting from a collection page goes back to the list', (
    tester,
  ) async {
    await openCollections(tester);
    await tester.tap(find.text('Dinners'));
    await tester.pumpAndSettle();
    await chooseFromMenu(tester, l10n.delete);
    await tester.tap(find.widgetWithText(FilledButton, l10n.delete));
    await tester.pumpAndSettle();

    expect(find.text(l10n.emptyCollections), findsOneWidget);
  });

  testWidgets('tapping a meal opens its page', (tester) async {
    await openCollections(tester);
    await tester.tap(find.text('Dinners'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(pasta.name));
    await tester.pumpAndSettle();

    expect(find.text(l10n.ingredients), findsOneWidget);
  });
}
