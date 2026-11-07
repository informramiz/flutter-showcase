import 'package:flutter_showcase/core/strings.dart';
import 'package:flutter_showcase/features/favourites/data/favourites_repository.dart';
import 'package:flutter_showcase/features/favourites/presentation/favourites_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

void main() {
  testWidgets('shows the empty state with no favourites', (tester) async {
    await pumpScreen(tester, const FavouritesScreen(), stubbedRepository());

    expect(find.text(Strings.emptyFavourites), findsOneWidget);
    expect(find.text(Strings.emptyFavouritesHint), findsOneWidget);
  });

  testWidgets('lists saved favourites and removing one updates the list', (
    tester,
  ) async {
    final seed = await fakePrefs();
    await FavouritesRepository(seed).save([pasta, curry]);
    await pumpScreen(
      tester,
      const FavouritesScreen(),
      stubbedRepository(),
      prefs: {favouritesKey: seed.getString(favouritesKey)!},
    );

    expect(find.text('Spaghetti Bolognese'), findsOneWidget);
    expect(find.text('Chicken Curry'), findsOneWidget);

    await tester.tap(find.byTooltip(Strings.removeFavourite).first);
    await tester.pump();

    expect(find.text('Spaghetti Bolognese'), findsNothing);
    expect(find.text('Chicken Curry'), findsOneWidget);
  });

  testWidgets('tapping a favourite opens its detail', (tester) async {
    final seed = await fakePrefs();
    await FavouritesRepository(seed).save([pasta]);
    final repository = stubbedRepository();
    await pumpApp(
      tester,
      repository,
      prefs: {favouritesKey: seed.getString(favouritesKey)!},
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.favouritesTab).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spaghetti Bolognese'));
    await tester.pumpAndSettle();

    verify(() => repository.meal('1')).called(1);
    expect(find.text(Strings.ingredients), findsOneWidget);
  });
}
