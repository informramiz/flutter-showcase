import 'package:flutter/material.dart';
import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

void main() {
  Future<void> openFirstMeal(WidgetTester tester) async {
    await tester.tap(find.text('Spaghetti Bolognese'));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a meal opens its detail', (tester) async {
    final repository = stubbedRepository();
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    await openFirstMeal(tester);

    verify(() => repository.meal('1')).called(1);
    expect(find.text(l10n.ingredients), findsOneWidget);
    expect(find.text('Spaghetti'), findsOneWidget);
    expect(find.text('200g'), findsOneWidget);
    expect(find.text(l10n.instructions), findsOneWidget);
    expect(find.textContaining('Boil the pasta.'), findsOneWidget);
    expect(find.text('Meat'), findsOneWidget);
  });

  testWidgets('favouriting from the detail shows up in Favourites', (
    tester,
  ) async {
    await pumpApp(tester, stubbedRepository());
    await tester.pumpAndSettle();
    await openFirstMeal(tester);

    await tester.tap(find.byTooltip(l10n.addFavourite));
    await tester.pump();
    expect(find.byTooltip(l10n.removeFavourite), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.favouritesTab).last);
    await tester.pumpAndSettle();

    expect(find.text('Spaghetti Bolognese'), findsOneWidget);
    expect(find.text(l10n.emptyFavourites), findsNothing);
  });

  testWidgets('a failing lookup shows an error and retry recovers', (
    tester,
  ) async {
    final repository = stubbedRepository();
    var calls = 0;
    when(() => repository.meal(any(), forceRefresh: anyForce)).thenAnswer((_) {
      calls++;
      return calls == 1
          ? failed<Meal>(const ServerFailure(503))
          : fresh(pastaDetail);
    });
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await openFirstMeal(tester);

    expect(find.text(l10n.errorServerCode(503)), findsOneWidget);

    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();

    expect(find.text(l10n.ingredients), findsOneWidget);
  });

  testWidgets('an unknown meal shows the not-found message', (tester) async {
    final repository = stubbedRepository();
    when(
      () => repository.meal(any(), forceRefresh: anyForce),
    ).thenAnswer((_) => failed(const NotFoundFailure()));
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await openFirstMeal(tester);

    expect(find.text(l10n.notFound), findsOneWidget);
    expect(find.byTooltip(l10n.addFavourite), findsNothing);
  });

  testWidgets('a meal without instructions or ingredients still renders', (
    tester,
  ) async {
    final repository = stubbedRepository();
    when(
      () => repository.meal(any(), forceRefresh: anyForce),
    ).thenAnswer((_) => fresh(pasta));
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await openFirstMeal(tester);

    expect(find.text(l10n.ingredients), findsNothing);
    expect(find.text(l10n.instructions), findsNothing);
    expect(find.byType(Chip), findsNWidgets(2));
  });

  testWidgets('pull to refresh revalidates the recipe', (tester) async {
    final repository = stubbedRepository();
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await openFirstMeal(tester);

    await tester.fling(
      find
          .descendant(
            of: find.byType(RefreshIndicator),
            matching: find.byType(Scrollable),
          )
          .first,
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    verify(() => repository.meal('1', forceRefresh: true)).called(1);
  });
}
