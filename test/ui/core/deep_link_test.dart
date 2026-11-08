import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/harness.dart';

/// Delivers [uri] the way the engine does when the OS opens a deep link.
Future<void> openDeepLink(WidgetTester tester, String uri) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(
      MethodCall('pushRouteInformation', {'location': uri, 'state': null}),
    ),
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a meal link opens the meal detail', (tester) async {
    await pumpApp(tester, stubbedRepository());
    await tester.pumpAndSettle();

    await openDeepLink(tester, 'mealfinder://open/meal/${pasta.id}');

    expect(find.text(l10n.ingredients), findsOneWidget);
  });

  testWidgets('a planner link opens the planner', (tester) async {
    await pumpApp(tester, stubbedRepository());
    await tester.pumpAndSettle();

    await openDeepLink(tester, 'mealfinder://open/planner');

    expect(find.text(l10n.emptyPlan), findsOneWidget);
  });

  testWidgets('an unknown link shows not found', (tester) async {
    await pumpApp(tester, stubbedRepository());
    await tester.pumpAndSettle();

    await openDeepLink(tester, 'mealfinder://open/nowhere');

    expect(find.text(l10n.pageNotFound), findsOneWidget);
  });

  testWidgets('tapping a cook reminder opens its meal', (tester) async {
    final reminders = FakeCookReminderService();
    await pumpApp(tester, stubbedRepository(), cookReminderService: reminders);
    await tester.pumpAndSettle();

    reminders.taps.add('/meal/${pasta.id}');
    await tester.pumpAndSettle();

    expect(find.text(l10n.ingredients), findsOneWidget);
  });
}
