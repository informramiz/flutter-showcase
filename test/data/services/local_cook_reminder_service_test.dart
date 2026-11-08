import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_showcase/data/services/local_cook_reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockAndroid extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _MockIos extends Mock implements IOSFlutterLocalNotificationsPlugin {}

class _FakeSettings extends Fake implements InitializationSettings {}

class _FakeDetails extends Fake implements NotificationDetails {}

void main() {
  late _MockPlugin plugin;
  late LocalCookReminderService service;
  DidReceiveNotificationResponseCallback? onTap;

  setUpAll(() {
    registerFallbackValue(_FakeSettings());
    registerFallbackValue(_FakeDetails());
    registerFallbackValue(AndroidScheduleMode.inexact);
    registerFallbackValue(tz.TZDateTime.utc(2026));
  });

  setUp(() {
    plugin = _MockPlugin();
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((invocation) async {
      onTap =
          invocation.namedArguments[#onDidReceiveNotificationResponse]
              as DidReceiveNotificationResponseCallback?;
      return true;
    });
    when(plugin.getNotificationAppLaunchDetails).thenAnswer(
      (_) async => const NotificationAppLaunchDetails(
        true,
        notificationResponse: NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '/meal/1',
        ),
      ),
    );
    service = LocalCookReminderService(
      plugin,
      localTimeZone: () async => 'Europe/Madrid',
    );
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('schedules a weekly, inexact reminder in the local zone', () async {
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
        matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
      ),
    ).thenAnswer((_) async {});
    final at = DateTime(2026, 11, 9, 18);

    expect(service.isSupported, isTrue);
    await service.scheduleWeekly(
      id: 7,
      at: at,
      title: 'Cook',
      body: 'Pasta',
      route: '/meal/1',
    );

    final scheduled =
        verify(
              () => plugin.zonedSchedule(
                id: 7,
                scheduledDate: captureAny(named: 'scheduledDate'),
                notificationDetails: any(named: 'notificationDetails'),
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                title: 'Cook',
                body: 'Pasta',
                payload: '/meal/1',
                matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
              ),
            ).captured.single
            as tz.TZDateTime;
    expect(scheduled.location.name, 'Europe/Madrid');
    expect(scheduled.isAtSameMomentAs(at), isTrue);
  });

  test('cancel removes the reminder', () async {
    when(() => plugin.cancel(id: 7)).thenAnswer((_) async {});

    await service.cancel(7);

    verify(() => plugin.cancel(id: 7)).called(1);
  });

  test('emits the launching reminder, then later taps', () async {
    final routes = <String>[];
    service.tappedRoutes.listen(routes.add);
    await pumpEventQueue();

    onTap!(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '/meal/2',
      ),
    );
    onTap!(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
      ),
    );
    await pumpEventQueue();

    expect(routes, ['/meal/1', '/meal/2']);
  });

  test('asks Android for the notification permission', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final android = _MockAndroid();
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(android);
    when(android.requestNotificationsPermission).thenAnswer((_) async => true);

    expect(await service.requestPermission(), isTrue);
  });

  test('asks iOS for alert and sound permission', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final ios = _MockIos();
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(ios);
    when(
      () => ios.requestPermissions(alert: true, sound: true),
    ).thenAnswer((_) async => null);

    expect(await service.requestPermission(), isFalse);
  });

  test('other platforms report no permission', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    expect(await service.requestPermission(), isFalse);
  });
}
