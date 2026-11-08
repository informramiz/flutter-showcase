/// Schedules weekly cook reminders for planned meals and reports which ones
/// the user tapped. An interface so the UI never touches the plugin, tests
/// use a fake, and the web build gets [UnsupportedCookReminderService].
abstract interface class CookReminderService {
  /// Whether this platform can show scheduled reminders at all.
  bool get isSupported;

  /// Asks for notification permission. Returns whether it was granted.
  Future<bool> requestPermission();

  /// Shows a reminder at [at] and again every week at the same weekday and
  /// time. Tapping it opens [route]. Replaces any reminder with [id].
  Future<void> scheduleWeekly({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String route,
  });

  Future<void> cancel(int id);

  /// Routes of tapped reminders, starting with the one that launched the
  /// app, if any.
  Stream<String> get tappedRoutes;
}

/// Browsers can't schedule notifications, so on the web reminders are
/// hidden and every call does nothing.
class UnsupportedCookReminderService implements CookReminderService {
  const UnsupportedCookReminderService();

  @override
  bool get isSupported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleWeekly({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String route,
  }) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Stream<String> get tappedRoutes => const Stream.empty();
}
