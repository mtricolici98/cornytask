import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../plugins/flutter_notification_plugin.dart';

Future<void> scheduleDailyNotification() async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'Good Evening!',
    'This is your 9 PM notification.',
    _nextInstanceOfTenAM(),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_notification_channel',
        'Corny Reminder',
        channelDescription: 'Register your completed todos!',
        importance: Importance.high,
      ),
    ),
    matchDateTimeComponents: DateTimeComponents.time,
    uiLocalNotificationDateInterpretation:
    UILocalNotificationDateInterpretation.absoluteTime,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

tz.TZDateTime _nextInstanceOfTenAM() {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate =
  tz.TZDateTime(tz.local, now.year, now.month, now.day, 21);
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}
