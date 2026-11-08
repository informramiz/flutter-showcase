import 'package:flutter/material.dart';
import 'package:flutter_showcase/ui/core/widgets/meal_thumbnail.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

void main() {
  Finder mealHero(String id) => find.byWidgetPredicate(
    (w) => w is Hero && w.tag == mealHeroTag(id),
    skipOffstage: false,
  );

  testWidgets('the list thumbnail flies to the detail image', (tester) async {
    await pumpApp(tester, stubbedRepository());
    await tester.pumpAndSettle();
    expect(mealHero(pasta.id), findsOneWidget);

    await tester.tap(find.text(pasta.name));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Mid-flight: both heroes are in the tree and share one navigator,
    // which is what lets Flutter animate between them.
    final heroes = mealHero(pasta.id).evaluate().toList();
    expect(heroes, hasLength(2));
    expect(
      Navigator.of(heroes.first),
      same(Navigator.of(heroes.last)),
    );

    await tester.pumpAndSettle();
    expect(find.text(l10n.ingredients), findsOneWidget);
  });

  testWidgets('a favourite opens inside the Favourites tab', (tester) async {
    await pumpApp(tester, stubbedRepository(), favourites: [pasta]);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.favouritesTab).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(pasta.name));
    await tester.pumpAndSettle();

    expect(find.text(l10n.ingredients), findsOneWidget);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
  });
}
