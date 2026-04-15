import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _waterRemindersEnabledKey = 'water_reminders_enabled';

/// Fixed water reminder schedule — 7 reminders anchored to daily transitions.
/// Times are in the device's local timezone.
/// Quiet hours (10 PM – 7 AM) are enforced by not scheduling outside this range.
class _ReminderSlot {
  final int id;
  final int hour;
  final int minute;
  const _ReminderSlot(this.id, this.hour, this.minute);
}

const List<_ReminderSlot> _reminderSlots = [
  _ReminderSlot(100, 7, 0),   // Wake-up
  _ReminderSlot(101, 9, 0),   // Mid-morning
  _ReminderSlot(102, 11, 30), // Before lunch
  _ReminderSlot(103, 13, 30), // Mid-afternoon
  _ReminderSlot(104, 15, 30), // Late afternoon
  _ReminderSlot(105, 17, 30), // Early evening
  _ReminderSlot(106, 19, 30), // Dinner
];

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // In-memory cache so the settings UI can read the state synchronously after init.
  bool _enabled = false;
  bool get isEnabled => _enabled;

  static const _channelId = 'water_reminders';
  static const _channelName = 'Water Reminders';
  static const _channelDesc = 'Reminders to drink water throughout the day';

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    // Ensure Android notification channel exists.
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.defaultImportance,
    ));

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_waterRemindersEnabledKey) ?? false;

    if (_enabled) {
      await _scheduleAllReminders();
    }

    _initialized = true;
  }

  /// Toggle reminders. Requests permission when enabling.
  /// Returns true if the new state was applied (false if permission was denied).
  Future<bool> setEnabled(bool value) async {
    if (value) {
      final granted = await _requestPermissions();
      if (!granted) return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_waterRemindersEnabledKey, value);
    _enabled = value;

    if (value) {
      await _scheduleAllReminders();
    } else {
      await _cancelAllReminders();
    }
    return true;
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isIOS) {
      final iosImpl = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImpl?.requestNotificationsPermission();
      return granted ?? true; // null means API < 33 where permission is implicit.
    }
    return false;
  }

  Future<void> _scheduleAllReminders() async {
    await _cancelAllReminders();
    for (final slot in _reminderSlots) {
      await _scheduleSlot(slot);
    }
  }

  Future<void> _scheduleSlot(_ReminderSlot slot) async {
    final scheduledDate = _nextInstanceOf(slot.hour, slot.minute);
    final (title, body) = _contentForSlot(slot.id);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.zonedSchedule(
        slot.id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at this time.
      );
    } catch (e) {
      // Swallow scheduling errors (e.g. exact-alarm permission denied) — they are non-fatal.
      debugPrint('NotificationService: failed to schedule slot ${slot.id}: $e');
    }
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _cancelAllReminders() async {
    for (final slot in _reminderSlots) {
      await _plugin.cancel(slot.id);
    }
  }

  /// Called after the user logs water. Skips the next upcoming reminder if
  /// it would fire within 60 minutes from now — the user already hydrated,
  /// so they don't need the nudge.
  Future<void> rescheduleAfterLog() async {
    if (!_enabled) return;

    final now = DateTime.now();
    final upcoming = _nextSlotAfter(now);
    if (upcoming == null) return;

    final slotTime = DateTime(now.year, now.month, now.day, upcoming.hour, upcoming.minute);
    final diff = slotTime.difference(now);

    // Only suppress if the next slot is later today AND within 60 min.
    if (diff.inMinutes >= 0 && diff.inMinutes <= 60) {
      // Cancel today's instance; reschedule for tomorrow at the same time.
      await _plugin.cancel(upcoming.id);
      final tomorrow = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        upcoming.hour,
        upcoming.minute,
      ).add(const Duration(days: 1));
      await _rescheduleSlotAt(upcoming, tomorrow);
    }
  }

  Future<void> _rescheduleSlotAt(_ReminderSlot slot, tz.TZDateTime when) async {
    final (title, body) = _contentForSlot(slot.id);
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    try {
      await _plugin.zonedSchedule(
        slot.id,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('NotificationService: failed to reschedule slot ${slot.id}: $e');
    }
  }

  _ReminderSlot? _nextSlotAfter(DateTime now) {
    for (final slot in _reminderSlots) {
      if (slot.hour > now.hour ||
          (slot.hour == now.hour && slot.minute > now.minute)) {
        return slot;
      }
      if (slot.hour == now.hour && slot.minute == now.minute) {
        return slot;
      }
    }
    return null; // All today's slots are past.
  }

  /// Pick a deterministic title/body pair based on slot id.
  /// Kept bilingual inline because notifications fire outside a BuildContext.
  /// The device locale decides which message to show.
  (String, String) _contentForSlot(int slotId) {
    final isArabic = Platform.localeName.toLowerCase().startsWith('ar');
    const arBodies = [
      'حان وقت شرب الماء 💧',
      'لا تنسَ شرب الماء',
      'جسمك يحتاج ماء',
      'استراحة سريعة للماء',
    ];
    const enBodies = [
      'Time to drink water 💧',
      "Don't forget to drink water",
      'Your body needs water',
      'Quick water break',
    ];
    final bodies = isArabic ? arBodies : enBodies;
    final title = isArabic ? 'اشرب ماء' : 'Drink Water';
    final body = bodies[(slotId - 100) % bodies.length];
    return (title, body);
  }

  // Exposed for debugging / tests.
  @visibleForTesting
  Future<List<PendingNotificationRequest>> pendingNotifications() {
    return _plugin.pendingNotificationRequests();
  }
}
