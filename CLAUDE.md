# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bilingual (Arabic RTL / English LTR) habit tracking, fitness, and water app built with Flutter. Dark theme only, neon-green accent (#CDFF00). The app has four tabs: Habits, Fitness, Water, and Tools (settings, calculators, backup).

## Commands

```bash
flutter run                    # Run on connected device/emulator
flutter build apk              # Build Android APK (needs release signing, see README)
flutter build ios              # Build iOS
flutter analyze                # Run static analysis (uses flutter_lints)
flutter test                   # Run all tests
flutter test test/services/backup_codec_test.dart  # Run a single test file
```

## Architecture

**State management:** Provider (`ChangeNotifierProvider`) — four global providers registered in `main.dart`:
- `HabitProvider` — habits, habit entries, daily logs (mood/sleep), streaks, month navigation
- `FitnessProvider` — fitness weeks, nutrition, weight, steps, weekly assessments, body measurements, macro targets, step goal, health sync
- `WaterProvider` — daily water entries and goal; follows "today" across midnight/resume
- `LocaleProvider` — Arabic/English and text direction

Async loads that can race (month/week/date switching) use `RequestSequencer` (`lib/utils/request_sequencer.dart`) so stale results are dropped.

**Data layer:** Single `DatabaseService` singleton using sqflite. Entity tables use UUID primary keys; singleton tables (`macro_targets`, `water_goal`, `step_goal`, `user_profile`) use a fixed `id = 1` row and are written via upsert. Database is at schema version 6 — bump `_databaseVersion` and add an `_onUpgrade` step for schema changes. Models use `toMap()`/`fromMap()` for serialization.

**Backup/restore:** JSON export/import. `lib/services/backup_codec.dart` is the source of truth for backed-up tables, column types, and singleton defaults; it validates a backup fully (version, tables, columns, types, references) before `importFromJson` replaces data in a single transaction. Keep it in sync with the schema when adding tables or columns.

**Key tables:** `habits`, `habit_entries`, `daily_logs`, `fitness_weeks`, `nutrition_entries`, `weight_entries`, `weekly_assessments`, `body_measurements`, `macro_targets`, `water_goal`, `water_entries`, `step_entries`, `step_goal`, `user_profile`

**UI:** Direction set via a `Directionality` wrapper in `MaterialApp.builder`, driven by `LocaleProvider`. `MainShell` uses `IndexedStack` for tab persistence. Theme defined in `utils/app_theme.dart` with `AppColors` constants and `AppTheme.dark`.

**Fitness tracking** is organized around weekly cycles (`FitnessWeek` with start/end dates). Each week can have daily nutrition, weight, and step entries, a weekly assessment, and body measurements with optional photos.

**Health sync** (`HealthService`) is iOS-only (Apple HealthKit). Android Health Connect is not implemented; `HealthService.isSupported` is false there and the UI hides the toggle.

## Conventions

- User-facing strings live in `lib/l10n/app_localizations.dart` with Arabic and English variants (`_t(ar, en)`).
- Dates stored as ISO 8601 strings (`YYYY-MM-DD`) in the database.
- Database upserts use `ConflictAlgorithm.replace`.
- Models are immutable with `copyWith` methods.
