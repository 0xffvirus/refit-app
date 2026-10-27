<p align="center">
  <img src="AppIcons/appstore.png" width="140" alt="Refit logo" />
</p>

<h1 align="center">Refit</h1>

<p align="center">
  Build lasting habits, track your fitness, and stay hydrated — one day at a time.
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-%5E3.10.8-0175C2?logo=dart&logoColor=white" alt="Dart" /></a>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84" alt="Platform" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT" /></a>
</p>

---

Refit is an offline-first habit tracking and fitness app built with Flutter. It combines daily habit tracking, weekly fitness cycles, and water intake in a single dark-themed app. No account, no ads, no tracking — all data stays on your device.

## Features

### Habits
- Create custom daily habits and mark them complete from a grid
- Streaks, weekly overview, and monthly calendar
- Completion-rate statistics and habit ranking
- Daily mood and sleep logging

### Fitness
- Weekly fitness cycles with nutrition, weight, steps, and body measurements
- Calorie and macro tracking with customizable targets and averages
- Body measurement photos for side-by-side progress
- Weekly self-assessments
- Step tracking, with Apple Health sync on iOS

### Water
- Daily water intake tracking
- Reminder notifications
- Apple Health sync (iOS)

### Tools
- Water intake, calorie & macro, BMI, 1RM, body fat, and ideal weight calculators
- Profile-aware pre-fill so calculators use your saved data
- Apple Health sync toggle (iOS only)

### App
- Full Arabic and English support with RTL/LTR layouts
- Dark theme only, with a neon-green accent
- Local notifications and home-screen widgets
- JSON backup and restore
- Biometric app lock
- Onboarding and interactive tutorials

## Screenshots

| Nutrition | Tools | Water |
| :---: | :---: | :---: |
| <img src="docs/screenshots/1.png" width="220" alt="Nutrition tracking with calorie and macro goals" /> | <img src="docs/screenshots/2.png" width="220" alt="Tools and calculators" /> | <img src="docs/screenshots/3.png" width="220" alt="Water tracking" /> |

## Tech Stack

| Area | Choice |
| --- | --- |
| Framework | Flutter (Dart SDK ^3.10.8) |
| State management | `provider` (`ChangeNotifier`) |
| Local database | `sqflite` |
| Charts | `fl_chart` |
| Health data | `health` (Apple HealthKit, iOS only) |
| Notifications | `flutter_local_notifications` + `timezone` |
| Home widgets | `home_widget` |
| Auth | `local_auth` |
| Backup files | `share_plus`, `file_picker` |
| Media | `image_picker` |
| Onboarding | `tutorial_coach_mark` |
| Fonts | `google_fonts` |

## Architecture

- **State:** Four global `ChangeNotifier` providers in `lib/providers/` — `HabitProvider` (habits, entries, daily logs, streaks), `FitnessProvider` (fitness weeks, nutrition, weight, steps, measurements, assessments, macro targets), `WaterProvider`, and `LocaleProvider`.
- **Data:** A single `DatabaseService` singleton backed by sqflite. All tables use UUID primary keys, dates are stored as ISO 8601 strings, and inserts use `ConflictAlgorithm.replace`. The database is currently at schema version 6.
- **Backup:** JSON export/import. Backups are validated in full (`lib/services/backup_codec.dart`) before anything is replaced, and restored in a single transaction, so an invalid file never touches existing data. Backups from older app versions are accepted.
- **UI:** RTL/LTR is driven by `LocaleProvider` via a `Directionality` wrapper. The theme lives in `lib/utils/app_theme.dart`.

## Project Structure

```
lib/
├── main.dart              # App entry, providers, and tab shell
├── l10n/                  # Arabic & English strings
├── models/                # Immutable models with toMap/fromMap + copyWith
├── providers/             # ChangeNotifier state (habit, fitness, water, locale)
├── screens/
│   ├── habit_tracker/     # Grid, calendar, stats, mood & sleep
│   ├── fitness_tracker/   # Weeks, nutrition, weight, steps, measurements, assessments
│   ├── water_tracker/     # Water intake
│   ├── settings/          # Tools: calculators, Apple Health sync, backup/restore, profile
│   └── onboarding/        # First-run onboarding
├── services/              # Database, health, notifications, widgets, tutorials
├── utils/                 # Theme and colors
└── widgets/               # Shared widgets
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) with Dart `^3.10.8`
- Android Studio or Xcode for running on a device/emulator

### Run

```bash
git clone https://github.com/0xffvirus/refit-app.git
cd refit-app
flutter pub get
flutter run
```

### Quality Checks

```bash
flutter analyze
flutter test
```

### Build

```bash
flutter build apk      # Android (requires release signing, below)
flutter build ios      # iOS
```

#### Android release signing

Release builds are never signed with the debug key implicitly — they fail with a clear error until signing is configured:

1. Create an upload keystore (keep it out of the repo):
   ```bash
   keytool -genkey -v -keystore ~/refit-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copy `android/key.properties.example` to `android/key.properties` (gitignored) and fill in `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
   In CI, set `REFIT_KEYSTORE_PATH`, `REFIT_KEYSTORE_PASSWORD`, `REFIT_KEY_ALIAS`, and `REFIT_KEY_PASSWORD` instead.

For a local release build you don't intend to distribute (e.g. `flutter run --release`), you can opt into debug signing explicitly with `REFIT_ALLOW_DEBUG_SIGNING=true`.

## Platform Notes

- **iOS:** Health sync (nutrition, weight, sleep, steps read; water write) uses Apple HealthKit. Usage descriptions are declared in `ios/Runner/Info.plist`; enable the HealthKit capability in Xcode before building. Camera and photo library access are used for body measurement photos.
- **Android:** Health sync is not available — Health Connect is not integrated, so the Apple Health section is hidden and all fitness data is entered manually. Water reminders request the notification permission (Android 13+) and use inexact scheduling, so no exact-alarm permission is needed; they are restored after a reboot.
- **Storage:** Everything is stored locally with sqflite — there is no backend service.

## Privacy

All data stays on your device. No account is required, and nothing is sent to a server. See [privacy_policy.md](privacy_policy.md) for details.

## Contributing

Contributions are welcome. For larger changes, please open an issue first to discuss the approach.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Run `flutter analyze` and `flutter test` before committing
4. Open a pull request

## License

Released under the [MIT License](LICENSE).
