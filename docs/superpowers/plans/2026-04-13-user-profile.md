# User Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a user profile system that collects name, gender, age, height, weight — shown at onboarding for new users, editable from Settings, and used to pre-fill calculators.

**Architecture:** New `user_profile` singleton table (DB v6) with a `UserProfile` model. Onboarding screen shown on first launch (skipped for existing users via migration). Profile card at the top of Settings, profile edit screen reuses the same form widget. Calculators read profile on init to pre-fill fields.

**Tech Stack:** Flutter, sqflite, Provider pattern (existing)

---

## File Structure

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `lib/models/user_profile.dart` | UserProfile model with toMap/fromMap/copyWith |
| Create | `lib/widgets/profile_form.dart` | Shared form widget used by onboarding + edit screen |
| Create | `lib/screens/onboarding/onboarding_screen.dart` | First-launch onboarding page |
| Create | `lib/screens/settings/profile_edit_screen.dart` | Profile editing screen |
| Modify | `lib/services/database_service.dart` | New table, migration v5→v6, CRUD, backup/restore |
| Modify | `lib/l10n/app_localizations.dart` | New localized strings |
| Modify | `lib/main.dart` | Onboarding routing logic |
| Modify | `lib/screens/settings/settings_screen.dart` | Profile card at top of settings list |
| Modify | `lib/screens/settings/settings_screen.dart` | Pre-fill water, macro, BMI calculators |
| Modify | `lib/screens/settings/body_fat_screen.dart` | Pre-fill from profile |
| Modify | `lib/screens/settings/ideal_weight_screen.dart` | Pre-fill from profile |

---

### Task 1: UserProfile Model

**Files:**
- Create: `lib/models/user_profile.dart`

- [ ] **Step 1: Create the UserProfile model**

```dart
enum Gender { male, female }

class UserProfile {
  final String? name;
  final Gender? gender;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final bool onboardingSeen;

  UserProfile({
    this.name,
    this.gender,
    this.age,
    this.heightCm,
    this.weightKg,
    this.onboardingSeen = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'name': name,
      'gender': gender?.name,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'onboarding_seen': onboardingSeen ? 1 : 0,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final genderStr = map['gender'] as String?;
    return UserProfile(
      name: map['name'] as String?,
      gender: genderStr == 'male'
          ? Gender.male
          : genderStr == 'female'
              ? Gender.female
              : null,
      age: map['age'] as int?,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      onboardingSeen: (map['onboarding_seen'] as int?) == 1,
    );
  }

  UserProfile copyWith({
    String? name,
    Gender? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    bool? onboardingSeen,
  }) {
    return UserProfile(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    );
  }

  bool get isEmpty =>
      name == null && gender == null && age == null && heightCm == null && weightKg == null;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/models/user_profile.dart
git commit -m "feat(profile): add UserProfile model"
```

---

### Task 2: Database — Table, Migration, CRUD

**Files:**
- Modify: `lib/services/database_service.dart`

- [ ] **Step 1: Bump database version from 5 to 6**

Change line 19:
```dart
const _databaseVersion = 6;
```

- [ ] **Step 2: Add user_profile table creation to `_onCreate`**

Add after the step_goal table creation and its default insert (around line 218), before the default habits seed:

```dart
// ── user profile (singleton) ──
await db.execute('''
  CREATE TABLE user_profile (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    name TEXT,
    gender TEXT,
    age INTEGER,
    height_cm REAL,
    weight_kg REAL,
    onboarding_seen INTEGER NOT NULL DEFAULT 0
  )
''');
await db.insert('user_profile', {'id': 1, 'onboarding_seen': 0});
```

- [ ] **Step 3: Add v5→v6 migration to `_onUpgrade`**

Add after the v4→v5 migration block (around line 295):

```dart
if (oldVersion < 6) {
  await db.execute('''
    CREATE TABLE user_profile (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      name TEXT,
      gender TEXT,
      age INTEGER,
      height_cm REAL,
      weight_kg REAL,
      onboarding_seen INTEGER NOT NULL DEFAULT 0
    )
  ''');
  // Existing user upgrading — skip onboarding
  await db.insert('user_profile', {'id': 1, 'onboarding_seen': 1});
}
```

- [ ] **Step 4: Add CRUD methods for user_profile**

Add after the existing step goal methods (around line 347):

```dart
// ── User Profile ──

Future<UserProfile> fetchUserProfile() async {
  final db = await database;
  final rows = await db.query('user_profile', where: 'id = ?', whereArgs: [1]);
  if (rows.isEmpty) {
    return UserProfile();
  }
  return UserProfile.fromMap(rows.first);
}

Future<void> updateUserProfile(UserProfile profile) async {
  final db = await database;
  await db.update(
    'user_profile',
    profile.toMap(),
    where: 'id = ?',
    whereArgs: [1],
  );
}
```

Add the import at the top of the file:
```dart
import '../models/user_profile.dart';
```

- [ ] **Step 5: Add user_profile to backup/restore**

Add `'user_profile'` to the `_backupTables` list (around line 706):

```dart
static const _backupTables = [
  'habits',
  'habit_entries',
  'daily_logs',
  'fitness_weeks',
  'nutrition_entries',
  'weight_entries',
  'weekly_assessments',
  'body_measurements',
  'macro_targets',
  'water_goal',
  'water_entries',
  'step_entries',
  'step_goal',
  'user_profile',  // ADD THIS
];
```

In `importFromJson`, after restoring all tables (around line 756), force `onboarding_seen = 1` so importing a backup doesn't re-trigger onboarding:

```dart
// After the restore loop, inside the transaction:
await txn.update('user_profile', {'onboarding_seen': 1},
    where: 'id = ?', whereArgs: [1]);
```

- [ ] **Step 6: Verify the app compiles**

Run: `flutter analyze`
Expected: No errors related to database_service.dart

- [ ] **Step 7: Commit**

```bash
git add lib/services/database_service.dart
git commit -m "feat(profile): add user_profile table, migration v5→v6, CRUD, backup"
```

---

### Task 3: Localization Strings

**Files:**
- Modify: `lib/l10n/app_localizations.dart`

- [ ] **Step 1: Add profile-related strings**

Add a new section at the end of the class (before the closing `}`):

```dart
// ── Profile ──
String get profileTitle => _t('الملف الشخصي', 'Profile');
String get setupProfile => _t('إعداد الملف الشخصي', 'Set Up Your Profile');
String get welcomeTitle => _t('مرحبًا بك!', 'Welcome!');
String get welcomeSubtitle => _t('أدخل بياناتك لتجربة أفضل', 'Enter your info for a better experience');
String get profileName => _t('الاسم', 'Name');
String get profileAge => _t('العمر', 'Age');
String get profileHeight => _t('الطول (سم)', 'Height (cm)');
String get profileWeight => _t('الوزن (كجم)', 'Weight (kg)');
String get male => _t('ذكر', 'Male');
String get female => _t('أنثى', 'Female');
String get start => _t('ابدأ', 'Start');
String get skip => _t('تخطي', 'Skip');
String get save => _t('حفظ', 'Save');
String get profileSaved => _t('تم حفظ الملف الشخصي', 'Profile saved');
String get profileYears => _t('سنة', 'years');
String get profileCm => _t('سم', 'cm');
String get profileKg => _t('كجم', 'kg');
String get gender => _t('الجنس', 'Gender');
```

- [ ] **Step 2: Commit**

```bash
git add lib/l10n/app_localizations.dart
git commit -m "feat(profile): add localization strings for profile & onboarding"
```

---

### Task 4: Shared Profile Form Widget

**Files:**
- Create: `lib/widgets/profile_form.dart`

- [ ] **Step 1: Create the reusable form widget**

This widget is used by both the onboarding screen and the profile edit screen. It takes an optional initial `UserProfile` for pre-filling and calls `onSave` with the filled profile.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../utils/app_theme.dart';

class ProfileForm extends StatefulWidget {
  final UserProfile? initial;
  final String buttonLabel;
  final ValueChanged<UserProfile> onSave;

  const ProfileForm({
    super.key,
    this.initial,
    required this.buttonLabel,
    required this.onSave,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  Gender? _gender;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    if (p != null) {
      _nameController.text = p.name ?? '';
      _ageController.text = p.age?.toString() ?? '';
      _heightController.text = p.heightCm?.toString() ?? '';
      _weightController.text = p.weightKg?.toString() ?? '';
      _gender = p.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _submit() {
    final profile = UserProfile(
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      gender: _gender,
      age: int.tryParse(_ageController.text),
      heightCm: double.tryParse(_heightController.text),
      weightKg: double.tryParse(_weightController.text),
      onboardingSeen: true,
    );
    widget.onSave(profile);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: l.profileName),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Gender toggle
        Text(l.gender, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = Gender.male),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _gender == Gender.male ? AppColors.accent : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _gender == Gender.male ? AppColors.accent : AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      l.male,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _gender == Gender.male ? AppColors.background : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = Gender.female),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _gender == Gender.female ? AppColors.accent : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _gender == Gender.female ? AppColors.accent : AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      l.female,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _gender == Gender.female ? AppColors.background : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Age
        TextField(
          controller: _ageController,
          decoration: InputDecoration(labelText: l.profileAge),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Height
        TextField(
          controller: _heightController,
          decoration: InputDecoration(labelText: l.profileHeight),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Weight
        TextField(
          controller: _weightController,
          decoration: InputDecoration(labelText: l.profileWeight),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 24),

        // Submit button
        FilledButton(
          onPressed: _submit,
          child: Text(widget.buttonLabel),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/profile_form.dart
git commit -m "feat(profile): add shared ProfileForm widget"
```

---

### Task 5: Onboarding Screen

**Files:**
- Create: `lib/screens/onboarding/onboarding_screen.dart`

- [ ] **Step 1: Create the onboarding screen**

```dart
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/profile_form.dart';
import '../main_shell.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _skip(BuildContext context) async {
    final db = DatabaseService();
    await db.updateUserProfile(UserProfile(onboardingSeen: true));
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  Future<void> _save(BuildContext context, UserProfile profile) async {
    final db = DatabaseService();
    await db.updateUserProfile(profile);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => _skip(context),
            child: Text(l.skip, style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Text(
              l.welcomeTitle,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l.welcomeSubtitle,
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ProfileForm(
              buttonLabel: l.start,
              onSave: (profile) => _save(context, profile),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify import path for MainShell**

Check that `lib/screens/main_shell.dart` exists (the `MainShell` widget). Adjust the import path if it's elsewhere.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/onboarding/onboarding_screen.dart
git commit -m "feat(profile): add onboarding screen"
```

---

### Task 6: Profile Edit Screen

**Files:**
- Create: `lib/screens/settings/profile_edit_screen.dart`

- [ ] **Step 1: Create the profile edit screen**

```dart
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../widgets/profile_form.dart';

class ProfileEditScreen extends StatelessWidget {
  final UserProfile profile;

  const ProfileEditScreen({super.key, required this.profile});

  Future<void> _save(BuildContext context, UserProfile updated) async {
    final db = DatabaseService();
    await db.updateUserProfile(updated);
    if (!context.mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.profileSaved)),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ProfileForm(
            initial: profile,
            buttonLabel: l.save,
            onSave: (updated) => _save(context, updated),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/settings/profile_edit_screen.dart
git commit -m "feat(profile): add profile edit screen"
```

---

### Task 7: Onboarding Routing in main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Change `home` from a const to a FutureBuilder**

Replace the `home: const MainShell(),` line (line 75) in the MaterialApp with a FutureBuilder that checks onboarding status:

```dart
home: FutureBuilder<UserProfile>(
  future: DatabaseService().fetchUserProfile(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!snapshot.data!.onboardingSeen) {
      return const OnboardingScreen();
    }
    return const MainShell();
  },
),
```

- [ ] **Step 2: Add imports at the top of main.dart**

```dart
import 'models/user_profile.dart';
import 'screens/onboarding/onboarding_screen.dart';
```

- [ ] **Step 3: Verify the app launches correctly**

Run: `flutter run`
Expected: App should launch, and since the database will migrate from v5→v6 with `onboarding_seen = 1`, existing users see MainShell. Fresh installs (delete app first) see onboarding.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat(profile): add onboarding routing on app launch"
```

---

### Task 8: Profile Card in Settings Screen

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`

- [ ] **Step 1: Add state for UserProfile and load it on init**

In the `_SettingsScreenState` class, add a field and load it in `initState`:

```dart
UserProfile? _profile;

@override
void initState() {
  super.initState();
  _loadProfile();
  // ... existing tutorial init code
}

Future<void> _loadProfile() async {
  final profile = await DatabaseService().fetchUserProfile();
  if (mounted) setState(() => _profile = profile);
}
```

- [ ] **Step 2: Add profile card widget method**

Add a method to build the profile card:

```dart
Widget _buildProfileCard(BuildContext context) {
  final l = AppLocalizations.of(context);
  final p = _profile;
  final hasData = p != null && !p.isEmpty;
  final initials = hasData && p.name != null && p.name!.isNotEmpty
      ? p.name!.substring(0, 1).toUpperCase()
      : '?';

  return GestureDetector(
    onTap: () async {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileEditScreen(profile: p ?? UserProfile(onboardingSeen: true)),
        ),
      );
      if (result == true) _loadProfile();
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Initials avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name + stats
          Expanded(
            child: hasData
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name ?? l.profileTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (p.age != null) '${p.age} ${l.profileYears}',
                          if (p.heightCm != null) '${p.heightCm!.toStringAsFixed(0)} ${l.profileCm}',
                          if (p.weightKg != null) '${p.weightKg!.toStringAsFixed(0)} ${l.profileKg}',
                        ].join(' · '),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  )
                : Text(
                    l.setupProfile,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
          ),
          const Icon(Icons.chevron_left, color: AppColors.textTertiary),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 3: Insert profile card into the ListView children**

In the `build` method, add the profile card as the first child of the ListView `children` list (before the calculators Column at line 105):

```dart
children: [
  _buildProfileCard(context),
  const SizedBox(height: 24),
  Column(
    key: _calculatorsKey,
    // ... existing calculators
```

- [ ] **Step 4: Add imports**

```dart
import '../../models/user_profile.dart';
import 'profile_edit_screen.dart';
```

(Adjust relative paths based on the actual file location — settings_screen.dart is in `lib/screens/settings/`, so imports should use relative paths like `'../..models/user_profile.dart'` or the package import style already used in the file.)

- [ ] **Step 5: Verify it looks correct**

Run the app, go to the Tools/Settings tab. The profile card should appear at the top. Tap it to open the edit screen.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/settings/settings_screen.dart
git commit -m "feat(profile): add profile card to settings screen"
```

---

### Task 9: Pre-fill Calculators from Profile

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart` (water, macro, BMI calculators)
- Modify: `lib/screens/settings/body_fat_screen.dart`
- Modify: `lib/screens/settings/ideal_weight_screen.dart`

- [ ] **Step 1: Pre-fill Water Intake Calculator**

In `_WaterIntakeCalculatorScreenState` (around line 583), add `initState` to load the profile:

```dart
@override
void initState() {
  super.initState();
  _prefillFromProfile();
}

Future<void> _prefillFromProfile() async {
  final profile = await DatabaseService().fetchUserProfile();
  if (!mounted) return;
  if (profile.weightKg != null && _weightController.text.isEmpty) {
    _weightController.text = profile.weightKg!.toStringAsFixed(0);
  }
}
```

- [ ] **Step 2: Pre-fill Macro Calculator**

In `_MacroCalculatorScreenState` (around line 826), add `initState`:

```dart
@override
void initState() {
  super.initState();
  _prefillFromProfile();
}

Future<void> _prefillFromProfile() async {
  final profile = await DatabaseService().fetchUserProfile();
  if (!mounted) return;
  if (profile.weightKg != null && _weightController.text.isEmpty) {
    _weightController.text = profile.weightKg!.toStringAsFixed(0);
  }
  if (profile.heightCm != null && _heightController.text.isEmpty) {
    _heightController.text = profile.heightCm!.toStringAsFixed(0);
  }
  if (profile.age != null && _ageController.text.isEmpty) {
    _ageController.text = profile.age.toString();
  }
  if (profile.gender != null) {
    setState(() {
      _gender = profile.gender == Gender.male ? _Gender.male : _Gender.female;
    });
  }
}
```

- [ ] **Step 3: Pre-fill BMI Calculator**

In `_BmiCalculatorScreenState` (around line 1368), add `initState`:

```dart
@override
void initState() {
  super.initState();
  _prefillFromProfile();
}

Future<void> _prefillFromProfile() async {
  final profile = await DatabaseService().fetchUserProfile();
  if (!mounted) return;
  if (profile.weightKg != null && _weightController.text.isEmpty) {
    _weightController.text = profile.weightKg!.toStringAsFixed(0);
  }
  if (profile.heightCm != null && _heightController.text.isEmpty) {
    _heightController.text = profile.heightCm!.toStringAsFixed(0);
  }
}
```

- [ ] **Step 4: Pre-fill Body Fat Calculator**

In `_BodyFatScreenState` in `body_fat_screen.dart` (around line 16), add `initState`:

```dart
@override
void initState() {
  super.initState();
  _prefillFromProfile();
}

Future<void> _prefillFromProfile() async {
  final profile = await DatabaseService().fetchUserProfile();
  if (!mounted) return;
  if (profile.heightCm != null && _heightController.text.isEmpty) {
    _heightController.text = profile.heightCm!.toStringAsFixed(0);
  }
  if (profile.gender != null) {
    setState(() {
      _gender = profile.gender == Gender.male ? _BfGender.male : _BfGender.female;
    });
  }
}
```

Add import at top:
```dart
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
```

- [ ] **Step 5: Pre-fill Ideal Weight Calculator**

In `_IdealWeightScreenState` in `ideal_weight_screen.dart` (around line 17), add `initState`:

```dart
@override
void initState() {
  super.initState();
  _prefillFromProfile();
}

Future<void> _prefillFromProfile() async {
  final profile = await DatabaseService().fetchUserProfile();
  if (!mounted) return;
  if (profile.heightCm != null && _heightController.text.isEmpty) {
    _heightController.text = profile.heightCm!.toStringAsFixed(0);
  }
  if (profile.gender != null) {
    setState(() {
      _gender = profile.gender == Gender.male ? _IwGender.male : _IwGender.female;
    });
  }
}
```

Add import at top:
```dart
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
```

- [ ] **Step 6: Verify all calculators open with pre-filled data**

Run the app, fill in profile data, then open each calculator. Fields should be pre-filled. Changing values in calculators should NOT update the profile.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/settings/settings_screen.dart lib/screens/settings/body_fat_screen.dart lib/screens/settings/ideal_weight_screen.dart
git commit -m "feat(profile): pre-fill all calculators from user profile"
```

---

### Task 10: Final Verification

- [ ] **Step 1: Run static analysis**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 2: Test fresh install flow**

Delete the app from the device/emulator and run fresh. Onboarding should appear. Fill in data, tap Start. Verify profile card shows in Settings. Verify calculators are pre-filled.

- [ ] **Step 3: Test skip flow**

Delete and reinstall. Tap Skip on onboarding. Verify profile card shows "Set up your profile". Tap it, fill in data, save. Verify calculators now pre-fill.

- [ ] **Step 4: Test existing user upgrade**

If possible, install the old version first, then upgrade. Onboarding should NOT appear. Profile card should show "Set up your profile".

- [ ] **Step 5: Test backup/restore**

Fill in profile data. Export backup. Delete and reinstall app. Skip onboarding. Import backup. Verify profile data is restored and onboarding doesn't re-trigger.
