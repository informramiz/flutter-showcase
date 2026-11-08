import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/core/result/result.dart';
import 'package:flutter_showcase/domain/models/cached.dart';
import 'package:flutter_showcase/domain/models/meal.dart';
import 'package:flutter_showcase/ui/meals/meals_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

void main() {
  testWidgets('shows a spinner while loading, then the meals', (tester) async {
    final controller = StreamController<Result<Cached<List<Meal>>>>();
    addTearDown(controller.close);
    final repository = stubbedRepository();
    when(
      () => repository.search('', forceRefresh: anyForce),
    ).thenAnswer((_) => controller.stream);

    await pumpApp(tester, repository);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    controller.add(Success(Cached(const [pasta, curry], fetchedAt: testNow)));
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
    when(() => repository.search('', forceRefresh: anyForce)).thenAnswer((_) {
      calls++;
      return calls == 1
          ? failed<List<Meal>>(const NetworkFailure())
          : fresh(const [pasta]);
    });

    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text(l10n.errorNetwork), findsOneWidget);

    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();

    expect(find.text(l10n.errorNetwork), findsNothing);
    expect(find.text('Spaghetti Bolognese'), findsOneWidget);
  });

  testWidgets('shows the empty state when nothing matches', (tester) async {
    await pumpApp(tester, stubbedRepository(meals: const []));
    await tester.pumpAndSettle();

    expect(find.text(l10n.emptyMeals), findsOneWidget);
    expect(find.text(l10n.emptyMealsHint), findsOneWidget);
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
    verifyNever(() => repository.search(any(), forceRefresh: anyForce));

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

    await tester.tap(find.widgetWithText(ChoiceChip, l10n.allCategories));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.widgetWithText(ChoiceChip, l10n.allCategories),
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
      () => repository.categories(forceRefresh: anyForce),
    ).thenAnswer((_) => failed(const ServerFailure(500)));
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

    expect(find.text(l10n.offlineBanner), findsOneWidget);
  });

  testWidgets('hides the offline banner when online', (tester) async {
    await pumpApp(tester, stubbedRepository());
    await tester.pumpAndSettle();

    expect(find.text(l10n.offlineBanner), findsNothing);
  });

  testWidgets('the theme button switches to dark mode', (tester) async {
    await pumpApp(tester, stubbedRepository());
    await tester.pumpAndSettle();
    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.system);

    await tester.tap(find.byTooltip(l10n.toggleTheme));
    await tester.pumpAndSettle();

    expect(app().themeMode, ThemeMode.dark);
  });

  testWidgets('a failed refresh says how old the shown list is', (
    tester,
  ) async {
    final repository = stubbedRepository();
    when(() => repository.search('', forceRefresh: anyForce)).thenAnswer(
      (_) => Stream.value(
        Success(
          Cached(
            const [pasta],
            fetchedAt: testNow.subtract(const Duration(hours: 2)),
            refreshFailure: const NetworkFailure(),
          ),
        ),
      ),
    );
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    expect(
      find.text('${l10n.refreshFailed} · ${l10n.savedHoursAgo(2)}'),
      findsOneWidget,
    );
    expect(find.text('Spaghetti Bolognese'), findsOneWidget);
  });

  testWidgets('offline results from the device are labelled', (tester) async {
    final repository = stubbedRepository();
    when(() => repository.search('', forceRefresh: anyForce)).thenAnswer(
      (_) => Stream.value(
        const Success(Cached([pasta], refreshFailure: NetworkFailure())),
      ),
    );
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text(l10n.savedOnDevice), findsOneWidget);
  });

  testWidgets('a stale list shows a progress line while revalidating', (
    tester,
  ) async {
    final controller = StreamController<Result<Cached<List<Meal>>>>();
    addTearDown(controller.close);
    final repository = stubbedRepository();
    when(
      () => repository.search('', forceRefresh: anyForce),
    ).thenAnswer((_) => controller.stream);
    await pumpApp(tester, repository);

    controller.add(
      Success(Cached(const [pasta], fetchedAt: testNow, isRefreshing: true)),
    );
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    controller.add(Success(Cached(const [pasta, curry], fetchedAt: testNow)));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Chicken Curry'), findsOneWidget);
  });

  testWidgets('pull to refresh skips the cache', (tester) async {
    final repository = stubbedRepository();
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    await tester.fling(
      find.text('Spaghetti Bolognese'),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    verify(() => repository.search('', forceRefresh: true)).called(1);
    verify(() => repository.categories(forceRefresh: true)).called(1);
  });
}
