import 'package:flutter_showcase/data/services/cook_reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the web service is unsupported and does nothing', () async {
    const service = UnsupportedCookReminderService();

    expect(service.isSupported, isFalse);
    expect(await service.requestPermission(), isFalse);
    await service.scheduleWeekly(
      id: 1,
      at: DateTime(2026),
      title: 't',
      body: 'b',
      route: '/',
    );
    await service.cancel(1);
    expect(await service.tappedRoutes.isEmpty, isTrue);
  });
}
