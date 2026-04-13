# User Profile System Design

## Overview

Add a user profile that collects basic personal data (name, gender, age, height, weight) to pre-fill calculator fields across the app. Profile is collected via onboarding on first launch and editable from Settings.

## Data Model

New `user_profile` singleton table in SQLite (DB version bump to 6):

| Column           | Type    | Notes                        |
|------------------|---------|------------------------------|
| id               | INTEGER | Always 1 (singleton)         |
| name             | TEXT    | Nullable                     |
| gender           | TEXT    | 'male' or 'female', nullable |
| age              | INTEGER | Nullable                     |
| height_cm        | REAL    | Nullable                     |
| weight_kg        | REAL    | Nullable                     |
| onboarding_seen  | INTEGER | 0 = not seen, 1 = seen       |

All fields nullable so skipping onboarding leaves an empty row.

### Migration Strategy

- **Fresh install (no existing DB):** Create table, insert row with `onboarding_seen = 0`.
- **Existing user (upgrade from version < 6):** Create table, insert row with `onboarding_seen = 1`. This prevents existing users from seeing onboarding. They can fill in their profile from Settings.

## Model

`UserProfile` class in `lib/models/user_profile.dart`:
- Fields: `name`, `gender` (enum: male/female), `age`, `heightCm`, `weightKg`, `onboardingSeen`
- `toMap()` / `fromMap()` serialization (matches existing pattern)
- `copyWith()` method

## Onboarding Screen

**File:** `lib/screens/onboarding/onboarding_screen.dart`

**When shown:** App launch when `onboarding_seen == 0`.

**Layout:** Single scrollable page with:
1. Welcome header text (Arabic/English)
2. Name text field
3. Gender toggle (male/female)
4. Age number field
5. Height field (cm)
6. Weight field (kg)
7. "Start" button at bottom

**Navigation:**
- AppBar has a "Skip" button
- Both "Start" and "Skip" set `onboarding_seen = 1` and navigate to MainShell
- "Start" saves the filled fields; "Skip" saves an empty profile

**Launch detection:** In `main.dart`, after DB init, check `onboarding_seen`. If 0, show `OnboardingScreen` as initial route. If 1, show `MainShell`.

## Profile Card (Settings Screen)

**Location:** Top of the Settings screen ListView, above the Calculators section.

**Appearance:**
- Initials circle (from name) + name + quick stats row (age, height, weight)
- If profile is empty/incomplete: shows "Set up your profile" prompt text
- Tapping opens `ProfileEditScreen`

## Profile Edit Screen

**File:** `lib/screens/settings/profile_edit_screen.dart`

**Layout:** Same fields as onboarding (name, gender, age, height, weight) but:
- AppBar title: "Profile" (localized)
- "Save" button instead of "Start"
- Pre-filled with current profile data
- No skip button

## Calculator Pre-fill

Each calculator that uses matching fields reads from `UserProfile` on init:

| Calculator       | Pre-filled fields              |
|------------------|-------------------------------|
| BMI              | weight, height                |
| Body Fat         | gender, height                |
| Ideal Weight     | gender                        |
| Water Intake     | weight                        |
| Macro            | gender, weight, height, age   |
| One Rep Max      | (none - uses lifted weight)   |

Pre-fill is convenience only. Changing values in a calculator does NOT update the profile.

## Backup/Restore

- Add `user_profile` to the JSON export in `DatabaseService.exportToFile()`
- Add `user_profile` import in `DatabaseService.importFromFile()`
- On import: restore profile data but keep `onboarding_seen = 1` (don't re-trigger onboarding)

## Localization

New strings added to both `app_ar.arb` and `app_en.arb`:
- Onboarding: welcome title, welcome subtitle, field labels, start button, skip button
- Profile card: "Set up your profile", stats labels
- Profile edit: screen title, save button
- Field labels: name, gender, male, female, age, height, weight (if not already present)

## Files to Create

- `lib/models/user_profile.dart` — model
- `lib/screens/onboarding/onboarding_screen.dart` — onboarding
- `lib/screens/settings/profile_edit_screen.dart` — profile editor

## Files to Modify

- `lib/services/database_service.dart` — new table, migration, CRUD methods, backup/restore
- `lib/screens/settings/settings_screen.dart` — profile card at top
- `lib/main.dart` — onboarding routing logic
- `lib/l10n/app_ar.arb` — Arabic strings
- `lib/l10n/app_en.arb` — English strings
- Calculator screens/methods — pre-fill from profile on init
