import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:front/model/events/event_model.dart';
import 'package:front/config/firebase_api.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class EventReminderService {
  static bool _tzInitialized = false;

  static Future<void> _ensureTimezoneInitialized() async {
    if (_tzInitialized) return;
    tz.initializeTimeZones();
    // Default to UTC to avoid lookup issues when timezone name is not available.
    tz.setLocalLocation(tz.getLocation('UTC'));
    _tzInitialized = true;
  }

  static Future<void> scheduleEventReminders({
    required EventModel event,
    String? bookingSummary,
  }) async {
    if (kIsWeb) {
      debugPrint(
        '[EventReminderService] Web detected, skipping local notifications.',
      );
      return;
    }

    final FlutterLocalNotificationsPlugin plugin =
        FirebaseApi.localNotificationsPlugin;
    await _ensureTimezoneInitialized();

    final DateTime eventTime = event.eventDateTime;
    final DateTime now = DateTime.now();

    final List<_ReminderDefinition> reminders = [
      _ReminderDefinition(
        triggerTime: eventTime.subtract(const Duration(hours: 24)),
        title: 'Upcoming event: ${event.eventName}',
        body:
            'Your event "${event.eventName}" starts in 24 hours. ${bookingSummary ?? ''}',
      ),
      _ReminderDefinition(
        triggerTime: eventTime.subtract(const Duration(hours: 1)),
        title: 'Starting soon',
        body:
            '"${event.eventName}" starts in 1 hour at ${event.eventLocation}. See you there!',
      ),
    ];

    for (final reminder in reminders) {
      if (!reminder.triggerTime.isAfter(now)) continue;
      try {
        final int notificationId =
            reminder.triggerTime.millisecondsSinceEpoch ~/ 1000;
        final tz.TZDateTime scheduledDate =
            tz.TZDateTime.from(reminder.triggerTime, tz.local);
        await plugin.zonedSchedule(
          notificationId,
          reminder.title,
          reminder.body,
          scheduledDate,
          FirebaseApi.defaultNotificationDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('[EventReminderService] Failed to schedule reminder: $e');
      }
    }
  }
}

class _ReminderDefinition {
  final DateTime triggerTime;
  final String title;
  final String body;

  _ReminderDefinition({
    required this.triggerTime,
    required this.title,
    required this.body,
  });
}


