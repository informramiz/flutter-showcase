import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_showcase/data/services/cook_reminder_service.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Returns the device's IANA time zone, e.g. `Europe/Madrid`.
typedef LocalTimeZone = Future<String> Function();

Future<String> _deviceTimeZone() async =>
    (await FlutterTimezone.getLocalTimezone()).identifier;

/// [CookReminderService] for Android and iOS, backed by
/// flutter_local_notifications. Reminders are inexact: a cook reminder a few
/// minutes late is fine, and it avoids the exact-alarm permission.
class LocalCookReminderService implements CookReminderService {
  LocalCookReminderService(
    this._plugin, {
    LocalTimeZone localTimeZone = _deviceTimeZone,
  }) : _localTimeZone = localTimeZone;

  static const _channel = AndroidNotificationDetails(
    'cook_reminders',
    'Cook reminders',
    channelDescription: 'A reminder an hour before a planned meal.',
  );
  static const _details = NotificationDetails(
    android: _channel,
    iOS: DarwinNotificationDetails(),
  );

  final FlutterLocalNotificationsPlugin _plugin;
  final LocalTimeZone _localTimeZone;
  final _taps = StreamController<String>();
  late final Future<void> _ready = _initialize();

  Future<void> _initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(await _localTimeZone()));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Ask for permission when the user turns a reminder on, not at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => _addTap(response.payload),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _addTap(launch!.notificationResponse?.payload);
    }
  }

  void _addTap(String? route) {
    if (route != null && route.isNotEmpty) _taps.add(route);
  }

  @override
  bool get isSupported => true;

  @override
  Future<bool> requestPermission() async {
    await _ready;
    final granted = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission(),
      TargetPlatform.iOS =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true),
      _ => false,
    };
    return granted ?? false;
  }

  @override
  Future<void> scheduleWeekly({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String route,
  }) async {
    await _ready;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: route,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _ready;
    await _plugin.cancel(id: id);
  }

  @override
  Stream<String> get tappedRoutes async* {
    await _ready;
    yield* _taps.stream;
  }
}
