import 'package:flutter/material.dart';
import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/core/strings.dart';
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
    expect(find.text(Strings.ingredients), findsOneWidget);
    expect(find.text('Spaghetti'), findsOneWidget);
    expect(find.text('200g'), findsOneWidget);
    expect(find.text(Strings.instructions), findsOneWidget);
    expect(find.textContaining('Boil the pasta.'), findsOneWidget);
    expect(find.text('Meat'), findsOneWidget);
  });

  testWidgets('favouriting from the detail shows up in Favourites', (
    tester,
  ) async {
    await pumpApp(tester, stubbedRepository());
    await tester.pumpAndSettle();
    await openFirstMeal(tester);

    await tester.tap(find.byTooltip(Strings.addFavourite));
    await tester.pump();
    expect(find.byTooltip(Strings.removeFavourite), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.favouritesTab).last);
    await tester.pumpAndSettle();

    expect(find.text('Spaghetti Bolognese'), findsOneWidget);
    expect(find.text(Strings.emptyFavourites), findsNothing);
  });

  testWidgets('a failing lookup shows an error and retry recovers', (
    tester,
  ) async {
    final repository = stubbedRepository();
    var calls = 0;
    when(() => repository.meal(any())).thenAnswer((_) async {
      calls++;
      return calls == 1
          ? const Err(ServerFailure(503))
          : const Success(pastaDetail);
    });
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await openFirstMeal(tester);

    expect(find.text(Strings.errorServer(503)), findsOneWidget);

    await tester.tap(find.text(Strings.retry));
    await tester.pumpAndSettle();

    expect(find.text(Strings.ingredients), findsOneWidget);
  });

  testWidgets('an unknown meal shows the not-found message', (tester) async {
    final repository = stubbedRepository();
    when(() => repository.meal(any())).thenAnswer(
      (_) async => const Err(NotFoundFailure()),
    );
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await openFirstMeal(tester);

    expect(find.text(Strings.notFound), findsOneWidget);
    expect(find.byTooltip(Strings.addFavourite), findsNothing);
  });

  testWidgets('a meal without instructions or ingredients still renders', (
    tester,
  ) async {
    final repository = stubbedRepository();
    when(() => repository.meal(any())).thenAnswer(
      (_) async => const Success(pasta),
    );
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await openFirstMeal(tester);

    expect(find.text(Strings.ingredients), findsNothing);
    expect(find.text(Strings.instructions), findsNothing);
    expect(find.byType(Chip), findsNWidgets(2));
  });
}
