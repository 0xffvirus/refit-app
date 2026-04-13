# Water Reminder Notifications — Design Spec

## Overview

Add local push notifications that remind the user to drink water throughout the day. Fixed schedule of 7 daily reminders anchored to natural daily transitions, with smart suppression when the user has recently logged water.

## Requirements

- 7 fixed daily reminders between 7:00 AM and 7:30 PM
- Quiet hours: 10 PM – 7 AM (enforced by schedule)
- Cap: 7 notifications/day maximum
- Skip next reminder if user logged water in the last 60 minutes
- Simple on/off toggle in Settings (default: off)
- No prayer time integration
- No user-configurable schedule

## Schedule

| # | Time    | Anchor          |
|---|---------|-----------------|
| 1 | 7:00 AM | Wake-up         |
| 2 | 9:00 AM | Mid-morning     |
| 3 | 11:30 AM| Before lunch    |
| 4 | 1:30 PM | Mid-afternoon   |
| 5 | 3:30 PM | Late afternoon  |
| 6 | 5:30 PM | Early evening   |
| 7 | 7:30 PM | Dinner          |

~250-300ml per reminder = ~2L total daily target.

## Architecture

### New Package

- `flutter_local_notifications` — schedule and manage local notifications on iOS/Android

### NotificationService (singleton)

**Location:** `lib/services/notification_service.dart`

Follows existing `HealthService` singleton pattern.

**State (persisted via SharedPreferences):**
- `water_reminders_enabled` — bool, default `false`

**Public API:**
- `initialize()` — request permissions, restore enabled state, schedule if enabled
- `setEnabled(bool enabled)` — toggle on/off, persist, schedule or cancel all
- `isEnabled` — getter for current state
- `rescheduleAfterLog()` — called after water is logged; cancels next upcoming reminder if it's within 60 minutes of now

**Internal:**
- `_scheduleAllReminders()` — schedule 7 daily repeating notifications at the fixed times
- `_cancelAllReminders()` — cancel all scheduled notifications
- `_cancelNextIfRecent()` — find the next upcoming reminder time; if it's within 60 minutes, cancel today's instance of that notification and reschedule it for tomorrow

### Notification IDs

Use fixed IDs 100–106 (one per reminder slot) to allow targeted cancel/reschedule.

### Notification Content

Rotating Arabic/English messages. The notification picks from a small set:

**Titles (Arabic / English):**
- "اشرب ماء" / "Drink Water"

**Bodies (Arabic / English):**
- "حان وقت شرب الماء 💧" / "Time to drink water 💧"
- "لا تنسَ شرب الماء" / "Don't forget to drink water"
- "جسمك يحتاج ماء" / "Your body needs water"
- "استراحة سريعة للماء" / "Quick water break"

Selection: use `notification_id % body_count` so each time slot always shows the same message (deterministic, no randomness needed).

### Integration Points

**WaterProvider.addWater():**
After inserting the entry, call `NotificationService.instance.rescheduleAfterLog()`.

**main.dart:**
Call `NotificationService.instance.initialize()` during app startup, after `WidgetsFlutterBinding.ensureInitialized()`.

**SettingsScreen:**
Add a "Water Reminders" toggle tile in a new "Notifications" section (or alongside existing sections). Uses `NotificationService.instance.setEnabled()` and `.isEnabled`.

### Localization

Add to `app_localizations.dart`:
- `waterReminders` — "تذكير شرب الماء" / "Water Reminders"
- `waterRemindersDesc` — "تلقي إشعارات لشرب الماء خلال اليوم" / "Get notifications to drink water throughout the day"
- Notification title and body strings (used in NotificationService)

### Platform Configuration

**iOS:**
- Request notification permissions via `flutter_local_notifications` iOS initialization
- Add notification capability in Xcode (already needed for local notifications)

**Android:**
- Add `POST_NOTIFICATIONS` permission for Android 13+
- Configure notification channel: id `water_reminders`, name "Water Reminders"

## Skip Logic Detail

When `rescheduleAfterLog()` is called:
1. Get current time
2. Find the next scheduled reminder time from the fixed schedule
3. If that reminder is within 60 minutes from now, cancel it for today
4. The daily repeating schedule means it will fire again tomorrow at the same time

This covers the common case: user drinks water at 8:45 AM, the 9:00 AM reminder gets cancelled. The 11:30 AM reminder still fires normally.

## Files to Create/Modify

### New Files
- `lib/services/notification_service.dart` — NotificationService singleton

### Modified Files
- `pubspec.yaml` — add `flutter_local_notifications`
- `lib/main.dart` — initialize NotificationService
- `lib/providers/water_provider.dart` — call rescheduleAfterLog() in addWater()
- `lib/screens/settings/settings_screen.dart` — add toggle tile
- `lib/l10n/app_localizations.dart` — add notification strings
- `android/app/src/main/AndroidManifest.xml` — POST_NOTIFICATIONS permission
- `ios/Runner/AppDelegate.swift` — notification setup if needed

## Out of Scope

- Prayer time integration
- Ramadan mode
- User-configurable schedule or quiet hours
- Notification sound customization
- Water amount in notification (e.g., "drink 250ml")
- Notification actions (e.g., "Log 250ml" button from notification)
