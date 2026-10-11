import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/interventions/domain/entities/intervention.dart';

class LocalReminderService {
  LocalReminderService._();

  static final LocalReminderService instance = LocalReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  Future<void> _initialize() => _initialization ??= _initializePlugin();

  Future<void> _initializePlugin() async {
    tz_data.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  Future<bool> requestPermission() async {
    await _initialize();
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  Future<int> scheduleFor(List<Intervention> interventions) async {
    await _initialize();
    await _plugin.cancelAll();
    final now = DateTime.now();
    var scheduledCount = 0;

    for (final intervention in interventions) {
      final date = intervention.scheduledAt;
      if (date == null || intervention.status == 'completed') continue;

      final reminderAt = date.toLocal().subtract(const Duration(hours: 1));
      if (!reminderAt.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: _notificationId(intervention.id),
        title: 'Intervention à venir',
        body: '${intervention.client} · ${intervention.address}',
        scheduledDate: tz.TZDateTime.from(reminderAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'intervention_reminders',
            'Rappels d’intervention',
            channelDescription: 'Rappel une heure avant une intervention.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: intervention.id,
      );
      scheduledCount++;
    }
    return scheduledCount;
  }

  Future<void> cancelAll() async {
    await _initialize();
    await _plugin.cancelAll();
  }

  int _notificationId(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
