# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Arabic-language (RTL) habit tracking and fitness app built with Flutter. Dark theme only, neon-green accent (#CDFF00). The app has three main tabs: Habits, Fitness, and Settings.

## Commands

```bash
flutter run                    # Run on connected device/emulator
flutter build apk              # Build Android APK
flutter build ios              # Build iOS
flutter analyze                # Run static analysis (uses flutter_lints)
flutter test                   # Run all tests
flutter test test/widget_test.dart  # Run a single test file
```

## Architecture

**State management:** Provider (`ChangeNotifierProvider`) — two global providers registered in `main.dart`:
- `HabitProvider` — habits, habit entries, daily logs (mood/sleep), streaks, month navigation
- `FitnessProvider` — fitness weeks, nutrition, weight, weekly assessments, body measurements, macro targets

**Data layer:** Single `DatabaseService` singleton using sqflite. All tables use UUID primary keys. Database is at version 2 (added `macro_targets` table in v2). Models use `toMap()`/`fromMap()` for serialization. Backup/restore via JSON export/import.

**Key tables:** `habits`, `habit_entries`, `daily_logs`, `fitness_weeks`, `nutrition_entries`, `weight_entries`, `weekly_assessments`, `body_measurements`, `macro_targets`

**UI:** RTL forced via `Directionality` wrapper in `MaterialApp.builder`. `MainShell` uses `IndexedStack` for tab persistence. Theme defined in `utils/app_theme.dart` with `AppColors` constants and `AppTheme.dark`.

**Fitness tracking** is organized around weekly cycles (`FitnessWeek` with start/end dates). Each week can have daily nutrition entries, weight entries, a weekly assessment, and body measurements with optional photos.

## Conventions

- Locale is hardcoded to Arabic (`ar`). All user-facing strings are in Arabic.
- Dates stored as ISO 8601 strings (`YYYY-MM-DD`) in the database.
- Database upserts use `ConflictAlgorithm.replace`.
- Models are immutable with `copyWith` methods.
