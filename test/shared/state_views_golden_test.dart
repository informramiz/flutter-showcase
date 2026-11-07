import 'package:flutter/material.dart';
import 'package:flutter_showcase/core/result/failure.dart';
import 'package:flutter_showcase/core/strings.dart';
import 'package:flutter_showcase/core/theme/app_theme.dart';
import 'package:flutter_showcase/shared/state_views.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _frame(ThemeData theme, Widget child) => MaterialApp(
  theme: theme,
  debugShowCheckedModeBanner: false,
  home: Scaffold(body: child),
);

void main() {
  const size = Size(360, 360);

  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('ErrorView golden ($name)', (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _frame(theme, ErrorView(error: const NetworkFailure(), onRetry: () {})),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/error_view_$name.png'),
      );
    }, tags: ['golden']);
  }

  testWidgets('EmptyView shows title and hint', (tester) async {
    await tester.pumpWidget(
      _frame(
        AppTheme.light,
        const EmptyView(
          title: Strings.emptyMeals,
          hint: Strings.emptyMealsHint,
        ),
      ),
    );
    expect(find.text(Strings.emptyMeals), findsOneWidget);
  });
}
