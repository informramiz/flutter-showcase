import 'package:flutter_showcase/ui/favourites/favourites_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

void main() {
  testWidgets('shows the empty state with no favourites', (tester) async {
    await pumpScreen(tester, const FavouritesScreen(), stubbedRepository());

    expect(find.text(l10n.emptyFavourites), findsOneWidget);
    expect(find.text(l10n.emptyFavouritesHint), findsOneWidget);
  });

  testWidgets('lists saved favourites and removing one updates the list', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const FavouritesScreen(),
      stubbedRepository(),
      favourites: [pasta, curry],
    );

    expect(find.text('Spaghetti Bolognese'), findsOneWidget);
    expect(find.text('Chicken Curry'), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.removeFavourite).first);
    await tester.pump();

    expect(find.text('Spaghetti Bolognese'), findsNothing);
    expect(find.text('Chicken Curry'), findsOneWidget);
  });

  testWidgets('tapping a favourite opens its detail', (tester) async {
    final repository = stubbedRepository();
    await pumpApp(tester, repository, favourites: [pasta]);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.favouritesTab).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spaghetti Bolognese'));
    await tester.pumpAndSettle();

    verify(() => repository.meal('1')).called(1);
    expect(find.text(l10n.ingredients), findsOneWidget);
  });
}
