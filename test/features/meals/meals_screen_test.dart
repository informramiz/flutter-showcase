import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/core/strings.dart';
import 'package:flutter_showcase/features/meals/domain/meal.dart';
import 'package:flutter_showcase/features/meals/presentation/meals_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

void main() {
  testWidgets('shows a spinner while loading, then the meals', (tester) async {
    final completer = Completer<Result<List<Meal>>>();
    final repository = stubbedRepository();
    when(() => repository.search('')).thenAnswer((_) => completer.future);

    await pumpApp(tester, repository);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const Success([pasta, curry]));
    await tester.pumpAndSettle();

    expect(find.text('Spaghetti Bolognese'), findsOneWidget);
    expect(find.text('Chicken Curry'), findsOneWidget);
    expect(find.text('Pasta · Italian'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows an error with retry, and retry loads the data', (
    tester,
  ) async {
    final repository = stubbedRepository();
    var calls = 0;
    when(() => repository.search('')).thenAnswer((_) async {
      calls++;
      return calls == 1 ? const Err(NetworkFailure()) : const Success([pasta]);
    });

    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text(Strings.errorNetwork), findsOneWidget);

    await tester.tap(find.text(Strings.retry));
    await tester.pumpAndSettle();

    expect(find.text(Strings.errorNetwork), findsNothing);
    expect(find.text('Spaghetti Bolognese'), findsOneWidget);
  });

  testWidgets('shows the empty state when nothing matches', (tester) async {
    await pumpApp(tester, stubbedRepository(meals: const []));
    await tester.pumpAndSettle();

    expect(find.text(Strings.emptyMeals), findsOneWidget);
    expect(find.text(Strings.emptyMealsHint), findsOneWidget);
  });

  testWidgets('typing searches once, after the debounce', (tester) async {
    final repository = stubbedRepository();
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    clearInteractions(repository);

    await tester.enterText(find.byType(TextField), 'pas');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'pasta');
    await tester.pump(const Duration(milliseconds: 100));
    verifyNever(() => repository.search(any()));

    await tester.pump(searchDebounce);
    await tester.pumpAndSettle();

    verify(() => repository.search('pasta')).called(1);
  });

  testWidgets('choosing a category filters by it', (tester) async {
    final repository = stubbedRepository();
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Pasta'));
    await tester.pumpAndSettle();

    verify(() => repository.byCategory('Pasta')).called(1);

    await tester.tap(find.widgetWithText(ChoiceChip, Strings.allCategories));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.widgetWithText(ChoiceChip, Strings.allCategories),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('hides the category row when categories fail to load', (
    tester,
  ) async {
    final repository = stubbedRepository();
    when(
      repository.categories,
    ).thenAnswer((_) async => const Err(ServerFailure(500)));
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Spaghetti Bolognese'), findsOneWidget);
  });

  testWidgets('shows an offline banner when the device is offline', (
    tester,
  ) async {
    await pumpApp(tester, stubbedRepository(), online: false);
    await tester.pumpAndSettle();

    expect(find.text(Strings.offlineBanner), findsOneWidget);
  });

  testWidgets('hides the offline banner when online', (tester) async {
    await pumpApp(tester, stubbedRepository());
    await tester.pumpAndSettle();

    expect(find.text(Strings.offlineBanner), findsNothing);
  });

  testWidgets('the theme button switches to dark mode', (tester) async {
    await pumpApp(tester, stubbedRepository());
    await tester.pumpAndSettle();
    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.system);

    await tester.tap(find.byTooltip(Strings.toggleTheme));
    await tester.pumpAndSettle();

    expect(app().themeMode, ThemeMode.dark);
  });
}
