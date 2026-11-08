import 'package:flutter/material.dart';
import 'package:flutter_showcase/domain/models/meal_collection.dart';
import 'package:flutter_showcase/ui/collections/collection_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

const dinners = MealCollection(id: 1, name: 'Dinners');
const lunches = MealCollection(id: 2, name: 'Lunches');

void main() {
  Future<FakeCollectionsRepository> openSheet(WidgetTester tester) async {
    final fake = FakeCollectionsRepository({
      dinners: const [],
      lunches: [pasta],
    });
    await pumpApp(tester, stubbedRepository(), collectionsRepository: fake);
    await tester.pumpAndSettle();
    await tester.tap(find.text(pasta.name));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.saveToCollection));
    await tester.pumpAndSettle();
    return fake;
  }

  bool checked(WidgetTester tester, int id) => tester
      .widget<CheckboxListTile>(find.byKey(ValueKey('save-to-$id')))
      .value!;

  testWidgets('shows which collections hold the meal', (tester) async {
    await openSheet(tester);

    expect(checked(tester, 1), isFalse);
    expect(checked(tester, 2), isTrue);
  });

  testWidgets('tapping a collection adds or removes the meal', (tester) async {
    final fake = await openSheet(tester);

    await tester.tap(find.text('Dinners'));
    await tester.tap(find.text('Lunches'));
    await tester.pumpAndSettle();

    expect(checked(tester, 1), isTrue);
    expect(checked(tester, 2), isFalse);
    expect(await fake.watchCollectionIdsFor(pasta.id).first, {1});
  });

  testWidgets('a new collection from the sheet holds the meal', (
    tester,
  ) async {
    final fake = await openSheet(tester);

    await tester.tap(find.text(l10n.newCollection));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('collection-name-field')),
      'Italian',
    );
    await tester.tap(find.text(l10n.create));
    await tester.pumpAndSettle();

    expect(checked(tester, 3), isTrue);
    expect(await fake.watchMeals(3).first, hasLength(1));
  });

  testWidgets('an unknown collection shows not found', (tester) async {
    await pumpScreen(
      tester,
      const CollectionDetailScreen(id: 99),
      stubbedRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.pageNotFound), findsOneWidget);
  });
}
