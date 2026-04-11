# First-Time User Tutorial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a coach-mark-based first-time user tutorial that runs once per tab on first visit, is skippable, and can be replayed from the Tools tab.

**Architecture:** Use the `tutorial_coach_mark` Flutter package wrapped by a thin `TutorialService` that manages `SharedPreferences` flags and orchestrates which steps fire on which tab. Target widgets on each tab screen expose `GlobalKey`s that the service uses to build a `TargetFocus` list. Empty-state tabs (Habits, Fitness) defer their "object interaction" step until real data exists. The Settings screen gains a "Replay tutorial" tile that resets all flags.

**Tech Stack:** Flutter 3.10+, `tutorial_coach_mark`, `shared_preferences` (already a dependency), Provider (already used for state).

**Spec:** `docs/superpowers/specs/2026-04-11-first-time-tutorial-design.md`

---

## File Map

**Create:**
- `lib/services/tutorial_service.dart` — flag management, tab entry coordination, replay reset
- `lib/widgets/tutorial/tutorial_theme.dart` — `buildCoachTooltip` helper (neon-green tooltip shell)
- `lib/widgets/tutorial/tutorial_steps.dart` — `buildTabTargets` helpers returning `List<TargetFocus>` per tab
- `test/services/tutorial_service_test.dart` — unit tests for `TutorialService` flag logic

**Modify:**
- `pubspec.yaml` — add `tutorial_coach_mark` dependency
- `lib/l10n/app_localizations.dart` — add tutorial strings
- `lib/main.dart` — `MainShell` tracks previous tab, calls `TutorialService.onTabEntered` on change
- `lib/screens/habit_tracker/habit_grid_screen.dart` — attach `GlobalKey`s, trigger tutorial in `initState` post-frame, watch habits for deferred step
- `lib/screens/fitness_tracker/week_list_screen.dart` — attach `GlobalKey` on FAB, watch weeks for deferred step
- `lib/screens/water_tracker/water_tracking_screen.dart` — attach `GlobalKey`s, trigger on entry
- `lib/screens/settings/settings_screen.dart` — convert to `StatefulWidget`, wrap calculators cluster in `Column` with `GlobalKey`, attach `GlobalKey`s, add `ScrollController`, add "Replay tutorial" tile, trigger on entry

---

## Task 1: Add the `tutorial_coach_mark` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dependency**

Edit `pubspec.yaml` — inside the `dependencies:` block, add this line after the existing `url_launcher` line (line 30):

```yaml
  tutorial_coach_mark: ^1.2.12
```

- [ ] **Step 2: Install the package**

Run: `flutter pub get`
Expected output: ends with `Got dependencies!` (or `Changed N dependencies!`).

- [ ] **Step 3: Verify the package imports cleanly**

Run: `flutter analyze lib/main.dart`
Expected: `No issues found!` (or pre-existing warnings only — no new errors).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add tutorial_coach_mark dependency for first-time tutorial"
```

---

## Task 2: Add tutorial localization strings

**Files:**
- Modify: `lib/l10n/app_localizations.dart` (insert before the closing `}` of the `AppLocalizations` class, around line 407)

- [ ] **Step 1: Add the strings**

Insert this block into `app_localizations.dart` immediately before the line `}` that closes the `AppLocalizations` class (before the `class _AppLocalizationsDelegate` declaration):

```dart
  // ── Tutorial ──
  String get tutorialSkip => _t('تخطّي', 'Skip');
  String get tutorialNext => _t('التالي', 'Next');
  String get tutorialDone => _t('تمام', 'Got it');
  String get tutorialReplayTitle => _t('إعادة عرض الشرح', 'Replay tutorial');
  String get tutorialReplaySubtitle =>
      _t('شاهد جولة المميزات من جديد', 'See the feature tour again');
  String get tutorialReplayConfirmSnack => _t(
        'سيتم عرض الشرح عند زيارة كل قسم',
        'Tutorial will show when you visit each tab',
      );

  // Habits tab
  String get tutorialHabitsAddTitle => _t('أضف أول عادة', 'Add your first habit');
  String get tutorialHabitsAddBody => _t(
        'اضغط هنا لإنشاء عادة يومية تريد متابعتها',
        'Tap here to create a daily habit you want to track',
      );
  String get tutorialHabitsTrackTitle =>
      _t('تتبّع تقدّمك', 'Track your progress');
  String get tutorialHabitsTrackBody => _t(
        'اضغط على العادة لتعليمها كمُنجَزة، واسحبها لليسار لحذفها',
        'Tap a habit to mark it done, swipe left to delete',
      );
  String get tutorialHabitsHistoryTitle => _t('شوف سجلّك', 'See your history');
  String get tutorialHabitsHistoryBody => _t(
        'التقويم والإحصائيات توضّح لك تقدّمك عبر الوقت',
        'Calendar and stats show your progress over time',
      );

  // Fitness tab
  String get tutorialFitnessWeekTitle => _t('ابدأ أسبوعك', 'Start your week');
  String get tutorialFitnessWeekBody => _t(
        'أنشئ أسبوع تدريب لتسجيل تغذيتك ووزنك وقياساتك',
        'Create a training week to log nutrition, weight, and measurements',
      );
  String get tutorialFitnessOpenTitle =>
      _t('كل شيء في مكانه', 'Everything in one place');
  String get tutorialFitnessOpenBody => _t(
        'افتح الأسبوع لتسجّل التغذية، الوزن، الخطوات، التقييم، والقياسات',
        'Open a week to log nutrition, weight, steps, assessment, and measurements',
      );

  // Water tab
  String get tutorialWaterLogTitle => _t('سجّل الماء بسرعة', 'Log water fast');
  String get tutorialWaterLogBody => _t(
        'اضغط على زجاجة لإضافة كمية الماء فوراً',
        'Tap a bottle to instantly add water',
      );
  String get tutorialWaterGoalTitle =>
      _t('حدّد هدفك اليومي', 'Set your daily goal');
  String get tutorialWaterGoalBody => _t(
        'اضبط كمية الماء المطلوبة كل يوم من هنا',
        'Adjust your daily water target here',
      );

  // Tools tab
  String get tutorialToolsCalculatorsTitle =>
      _t('حاسبات جاهزة', 'Built-in calculators');
  String get tutorialToolsCalculatorsBody => _t(
        '6 حاسبات تساعدك: الماء، الماكروز، BMI، 1RM، نسبة الدهون، والوزن المثالي',
        '6 calculators to help you: water, macros, BMI, 1RM, body fat, and ideal weight',
      );
  String get tutorialToolsHealthTitle =>
      _t('مزامنة Apple Health', 'Apple Health sync');
  String get tutorialToolsHealthBody => _t(
        'فعّل المزامنة لاستيراد وزنك وخطواتك تلقائياً',
        'Enable to auto-import your weight and steps',
      );
  String get tutorialToolsBackupTitle =>
      _t('احفظ بياناتك', 'Back up your data');
  String get tutorialToolsBackupBody => _t(
        'صدّر نسخة احتياطية حتى لا تفقد تقدّمك أبداً',
        'Export a backup so you never lose your progress',
      );
```

- [ ] **Step 2: Verify analyzer still clean**

Run: `flutter analyze lib/l10n/app_localizations.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/l10n/app_localizations.dart
git commit -m "feat(i18n): add tutorial strings (AR + EN)"
```

---

## Task 3: Write failing tests for `TutorialService`

**Files:**
- Create: `test/services/tutorial_service_test.dart`

- [ ] **Step 1: Write the test file**

Create `test/services/tutorial_service_test.dart` with the following content:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_game/services/tutorial_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TutorialService.instance.reload();
  });

  group('TutorialService flags', () {
    test('shouldShowFor returns true for all tabs when nothing is stored',
        () async {
      for (final tab in TabId.values) {
        expect(TutorialService.instance.shouldShowFor(tab), isTrue);
      }
    });

    test('markSeen flips flag and persists across reload', () async {
      await TutorialService.instance.markSeen(TabId.habits);
      expect(TutorialService.instance.shouldShowFor(TabId.habits), isFalse);

      // Simulate app restart: reload from prefs.
      await TutorialService.instance.reload();
      expect(TutorialService.instance.shouldShowFor(TabId.habits), isFalse);

      // Other tabs remain unseen.
      expect(TutorialService.instance.shouldShowFor(TabId.fitness), isTrue);
      expect(TutorialService.instance.shouldShowFor(TabId.water), isTrue);
      expect(TutorialService.instance.shouldShowFor(TabId.tools), isTrue);
    });

    test('markSeen is idempotent', () async {
      await TutorialService.instance.markSeen(TabId.water);
      await TutorialService.instance.markSeen(TabId.water);
      expect(TutorialService.instance.shouldShowFor(TabId.water), isFalse);
    });

    test('resetAllFlags clears all four', () async {
      for (final tab in TabId.values) {
        await TutorialService.instance.markSeen(tab);
      }
      await TutorialService.instance.resetAllFlags();
      for (final tab in TabId.values) {
        expect(TutorialService.instance.shouldShowFor(tab), isTrue);
      }
    });

    test('TabId has exactly the four expected values', () {
      expect(TabId.values, hasLength(4));
      expect(TabId.values, contains(TabId.habits));
      expect(TabId.values, contains(TabId.fitness));
      expect(TabId.values, contains(TabId.water));
      expect(TabId.values, contains(TabId.tools));
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/services/tutorial_service_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:habit_game/services/tutorial_service.dart'`.

- [ ] **Step 3: Commit**

```bash
git add test/services/tutorial_service_test.dart
git commit -m "test: add failing TutorialService flag tests"
```

---

## Task 4: Implement `TutorialService`

**Files:**
- Create: `lib/services/tutorial_service.dart`

- [ ] **Step 1: Create the file**

Create `lib/services/tutorial_service.dart` with:

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

enum TabId { habits, fitness, water, tools }

/// Manages first-time tutorial state across the 4 main tabs.
///
/// Flags live in SharedPreferences under `tutorial_<tab>_seen`. Each flag
/// flips to `true` once the user finishes or explicitly skips that tab's
/// tutorial. `resetAllFlags()` is wired to the "Replay tutorial" action in
/// the Tools tab.
///
/// Also tracks the currently visible overlay so MainShell can dismiss it
/// on tab switch without marking the tab as seen.
class TutorialService {
  TutorialService._();
  static final TutorialService instance = TutorialService._();

  static const _prefsPrefix = 'tutorial_';
  static const _prefsSuffix = '_seen';

  final Map<TabId, bool> _seen = {
    for (final t in TabId.values) t: false,
  };

  TutorialCoachMark? _activeCoach;
  bool _dismissing = false;

  /// Notified when a tab becomes eligible for its tutorial. Screens listen
  /// to trigger their local `showTutorial()` from a post-frame callback.
  final ValueNotifier<TabId?> pendingTab = ValueNotifier<TabId?>(null);

  String _keyFor(TabId tab) => '$_prefsPrefix${tab.name}$_prefsSuffix';

  /// Load (or reload) all flags from SharedPreferences.
  Future<void> reload() async {
    final prefs = await SharedPreferences.getInstance();
    for (final tab in TabId.values) {
      _seen[tab] = prefs.getBool(_keyFor(tab)) ?? false;
    }
  }

  /// Whether the tutorial for [tab] should still be shown.
  bool shouldShowFor(TabId tab) => _seen[tab] == false;

  /// Mark [tab] as seen and persist.
  Future<void> markSeen(TabId tab) async {
    _seen[tab] = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(tab), true);
  }

  /// Reset all four flags. Called from the "Replay tutorial" action.
  Future<void> resetAllFlags() async {
    for (final tab in TabId.values) {
      _seen[tab] = false;
    }
    final prefs = await SharedPreferences.getInstance();
    for (final tab in TabId.values) {
      await prefs.remove(_keyFor(tab));
    }
  }

  /// Called by MainShell when the user enters a tab (first launch or tab
  /// switch). If the tab's tutorial is unseen, pushes the tab onto
  /// [pendingTab] so the target screen can react.
  void onTabEntered(TabId tab) {
    if (shouldShowFor(tab)) {
      pendingTab.value = tab;
    }
  }

  /// Called by a screen once it has picked up and consumed a pending
  /// tab signal. Prevents the same signal firing twice.
  void clearPending(TabId tab) {
    if (pendingTab.value == tab) {
      pendingTab.value = null;
    }
  }

  /// Called by `showCoachMarks` when a new overlay is shown.
  void registerActive(TutorialCoachMark coach) {
    _activeCoach = coach;
    _dismissing = false;
  }

  /// Called by `showCoachMarks` callbacks after the overlay tears down.
  void clearActive() {
    _activeCoach = null;
    _dismissing = false;
  }

  /// True when the current overlay was torn down programmatically (tab
  /// switch). The `onFinish` hook in `showCoachMarks` checks this to
  /// decide whether to mark the tab as seen.
  bool get isDismissing => _dismissing;

  /// Dismisses the active overlay without marking the tab as seen.
  /// Called from `MainShell` when the user switches tabs mid-tutorial.
  void dismissActive() {
    final coach = _activeCoach;
    if (coach == null) return;
    _dismissing = true;
    coach.finish();
  }
}
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/services/tutorial_service_test.dart`
Expected: all 5 tests PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/services/tutorial_service.dart
git commit -m "feat: add TutorialService for first-time tutorial flag management"
```

---

## Task 5: Create the custom tooltip theme

**Files:**
- Create: `lib/widgets/tutorial/tutorial_theme.dart`

- [ ] **Step 1: Create the file**

Create `lib/widgets/tutorial/tutorial_theme.dart` with:

```dart
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/app_theme.dart';

/// Builds the tooltip content shown inside a tutorial_coach_mark spotlight.
///
/// Called once per target when building `TargetContent`. The position of
/// the tooltip (above/below the target) is controlled by the caller via
/// `ContentAlign`.
///
/// [currentStep] / [totalSteps] drive the "2 / 3" footer counter; pass
/// `totalSteps: 1` for single-step deferred tours so the footer shows
/// "1 / 1".
class TutorialTooltip extends StatelessWidget {
  final String title;
  final String body;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const TutorialTooltip({
    super.key,
    required this.title,
    required this.body,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isLast = currentStep == totalSteps;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.accent, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  l.tutorialSkip,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$currentStep / $totalSteps',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  isLast ? l.tutorialDone : l.tutorialNext,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analyzer**

Run: `flutter analyze lib/widgets/tutorial/tutorial_theme.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/tutorial/tutorial_theme.dart
git commit -m "feat(tutorial): custom neon-green tooltip widget"
```

---

## Task 6: Create the tutorial steps builder

**Files:**
- Create: `lib/widgets/tutorial/tutorial_steps.dart`

- [ ] **Step 1: Create the file**

Create `lib/widgets/tutorial/tutorial_steps.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../l10n/app_localizations.dart';
import '../../services/tutorial_service.dart';
import '../../utils/app_theme.dart';
import 'tutorial_theme.dart';

/// Convenience: build a single TargetFocus with our custom tooltip.
///
/// The tooltip's Next button calls `controller.next()` which advances to
/// the next step, or — on the last step — triggers TutorialCoachMark's
/// `onFinish` hook. The Skip button calls `controller.skip()` which
/// triggers the `onSkip` hook (which marks the tab as seen).
TargetFocus _target({
  required String identify,
  required GlobalKey key,
  required String title,
  required String body,
  required int step,
  required int total,
  required ContentAlign align,
  double paddingFocus = 8,
  ShapeLightFocus shape = ShapeLightFocus.RRect,
}) {
  return TargetFocus(
    identify: identify,
    keyTarget: key,
    paddingFocus: paddingFocus,
    shape: shape,
    radius: 12,
    contents: [
      TargetContent(
        align: align,
        builder: (ctx, controller) => TutorialTooltip(
          title: title,
          body: body,
          currentStep: step,
          totalSteps: total,
          onNext: () => controller.next(),
          onSkip: () => controller.skip(),
        ),
      ),
    ],
  );
}

/// Launches a coach-mark tour. Used by each tab screen.
///
/// [onSeen] is invoked when the user genuinely finishes or skips the
/// tutorial (should call `TutorialService.instance.markSeen(tab)`). It is
/// NOT called when `TutorialService.dismissActive()` tears the overlay
/// down (tab switch), so the flag remains unset and the tour fires again
/// on return.
void showCoachMarks({
  required BuildContext context,
  required List<TargetFocus> targets,
  required VoidCallback onSeen,
}) {
  final coach = TutorialCoachMark(
    targets: targets,
    colorShadow: Colors.black,
    opacityShadow: 0.75,
    paddingFocus: 8,
    hideSkip: true, // we render our own skip inside the tooltip
    onFinish: () {
      final dismissed = TutorialService.instance.isDismissing;
      TutorialService.instance.clearActive();
      if (!dismissed) onSeen();
    },
    onSkip: () {
      TutorialService.instance.clearActive();
      onSeen();
      return true;
    },
  );
  TutorialService.instance.registerActive(coach);
  coach.show(context: context);
}

// ═══════════════════════════════════════════════════════════════
// Habits tab
// ═══════════════════════════════════════════════════════════════

/// First-visit tour: FAB + top-right action icons. The "tap a habit" step
/// is deferred until the user has ≥ 1 habit (see [habitsDeferredTargets]).
List<TargetFocus> habitsFirstVisitTargets({
  required BuildContext context,
  required GlobalKey fabKey,
  required GlobalKey actionsKey,
}) {
  final l = AppLocalizations.of(context);
  const total = 2;
  return [
    _target(
      identify: 'habits_fab',
      key: fabKey,
      title: l.tutorialHabitsAddTitle,
      body: l.tutorialHabitsAddBody,
      step: 1,
      total: total,
      align: ContentAlign.top,
      shape: ShapeLightFocus.Circle,
    ),
    _target(
      identify: 'habits_actions',
      key: actionsKey,
      title: l.tutorialHabitsHistoryTitle,
      body: l.tutorialHabitsHistoryBody,
      step: 2,
      total: total,
      align: ContentAlign.bottom,
    ),
  ];
}

/// Deferred single-step tour shown the first time the user has at least
/// one habit. Points at the first `_HabitCard`.
List<TargetFocus> habitsDeferredTargets({
  required BuildContext context,
  required GlobalKey habitCardKey,
}) {
  final l = AppLocalizations.of(context);
  return [
    _target(
      identify: 'habits_card',
      key: habitCardKey,
      title: l.tutorialHabitsTrackTitle,
      body: l.tutorialHabitsTrackBody,
      step: 1,
      total: 1,
      align: ContentAlign.bottom,
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════
// Fitness tab
// ═══════════════════════════════════════════════════════════════

List<TargetFocus> fitnessFirstVisitTargets({
  required BuildContext context,
  required GlobalKey fabKey,
}) {
  final l = AppLocalizations.of(context);
  return [
    _target(
      identify: 'fitness_fab',
      key: fabKey,
      title: l.tutorialFitnessWeekTitle,
      body: l.tutorialFitnessWeekBody,
      step: 1,
      total: 1,
      align: ContentAlign.top,
      shape: ShapeLightFocus.Circle,
    ),
  ];
}

List<TargetFocus> fitnessDeferredTargets({
  required BuildContext context,
  required GlobalKey weekCardKey,
}) {
  final l = AppLocalizations.of(context);
  return [
    _target(
      identify: 'fitness_card',
      key: weekCardKey,
      title: l.tutorialFitnessOpenTitle,
      body: l.tutorialFitnessOpenBody,
      step: 1,
      total: 1,
      align: ContentAlign.bottom,
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════
// Water tab
// ═══════════════════════════════════════════════════════════════

List<TargetFocus> waterTargets({
  required BuildContext context,
  required GlobalKey bottlesKey,
  required GlobalKey goalKey,
}) {
  final l = AppLocalizations.of(context);
  const total = 2;
  return [
    _target(
      identify: 'water_bottles',
      key: bottlesKey,
      title: l.tutorialWaterLogTitle,
      body: l.tutorialWaterLogBody,
      step: 1,
      total: total,
      align: ContentAlign.top,
    ),
    _target(
      identify: 'water_goal',
      key: goalKey,
      title: l.tutorialWaterGoalTitle,
      body: l.tutorialWaterGoalBody,
      step: 2,
      total: total,
      align: ContentAlign.bottom,
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════
// Tools tab
// ═══════════════════════════════════════════════════════════════

/// Build the Tools tutorial. On Android, [appleHealthKey] may be null and
/// the Apple Health step will be skipped (counter reflows to 1/2 + 2/2).
List<TargetFocus> toolsTargets({
  required BuildContext context,
  required GlobalKey calculatorsKey,
  required GlobalKey? appleHealthKey, // null on Android
  required GlobalKey backupKey,
}) {
  final l = AppLocalizations.of(context);
  final hasHealth = appleHealthKey != null;
  final total = hasHealth ? 3 : 2;

  final targets = <TargetFocus>[
    _target(
      identify: 'tools_calculators',
      key: calculatorsKey,
      title: l.tutorialToolsCalculatorsTitle,
      body: l.tutorialToolsCalculatorsBody,
      step: 1,
      total: total,
      align: ContentAlign.bottom,
    ),
  ];

  if (hasHealth) {
    targets.add(
      _target(
        identify: 'tools_health',
        key: appleHealthKey,
        title: l.tutorialToolsHealthTitle,
        body: l.tutorialToolsHealthBody,
        step: 2,
        total: total,
        align: ContentAlign.bottom,
      ),
    );
  }

  targets.add(
    _target(
      identify: 'tools_backup',
      key: backupKey,
      title: l.tutorialToolsBackupTitle,
      body: l.tutorialToolsBackupBody,
      step: total,
      total: total,
      align: ContentAlign.top,
    ),
  );

  return targets;
}
```

- [ ] **Step 2: Verify analyzer**

Run: `flutter analyze lib/widgets/tutorial/tutorial_steps.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/tutorial/tutorial_steps.dart
git commit -m "feat(tutorial): per-tab step builders"
```

---

## Task 7: Wire up `MainShell` for tab-entry detection

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Initialize `TutorialService` at startup**

In `main.dart`, modify the `main()` function — add a call to `TutorialService.instance.reload()` right after `WidgetService.initialize()`. Also add the import.

Replace the top imports block with (add the new line):

```dart
import 'services/tutorial_service.dart';
```

Inside `main()`, between the `WidgetService.initialize()` line and the `getSavedLocale` line, insert:

```dart
  await TutorialService.instance.reload();
```

- [ ] **Step 2: Track previous tab index in `_MainShellState`**

In `_MainShellState` (inside `main.dart`):

Change the nav item `onTap` from:

```dart
onTap: () => setState(() => _currentIndex = index),
```

to:

```dart
onTap: () {
  if (index != _currentIndex) {
    // Dismiss any in-flight tutorial on the old tab without marking it
    // as seen — the tutorial will fire again when the user returns.
    TutorialService.instance.dismissActive();
  }
  setState(() => _currentIndex = index);
  _handleTabEntered(index);
},
```

Add this method inside `_MainShellState`:

```dart
void _handleTabEntered(int index) {
  const map = {
    0: TabId.habits,
    1: TabId.fitness,
    2: TabId.water,
    3: TabId.tools,
  };
  final tab = map[index];
  if (tab != null) {
    TutorialService.instance.onTabEntered(tab);
  }
}
```

- [ ] **Step 3: Verify analyzer and that app still builds**

Run: `flutter analyze lib/main.dart`
Expected: `No issues found!`

Run: `flutter build apk --debug` (or `flutter build ios --debug --no-codesign` on macOS without Android SDK)
Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat(tutorial): wire MainShell tab-entry detection"
```

---

## Task 8: Wire Habits tab (first-visit + deferred)

**Files:**
- Modify: `lib/screens/habit_tracker/habit_grid_screen.dart`

- [ ] **Step 1: Add imports**

At the top of `habit_grid_screen.dart`, add:

```dart
import '../../services/tutorial_service.dart';
import '../../widgets/tutorial/tutorial_steps.dart';
```

- [ ] **Step 2: Add state fields**

In `_HabitGridScreenState`, replace the existing field declarations and `initState` with:

```dart
class _HabitGridScreenState extends State<HabitGridScreen> {
  DateTime _selectedDate = DateTime.now();

  final _fabKey = GlobalKey();
  final _actionsKey = GlobalKey();
  final _firstHabitKey = GlobalKey();

  bool _firstVisitShown = false;
  bool _firstVisitComplete = false;
  bool _deferredShown = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<HabitProvider>().initialize();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Habits is the default landing tab — trigger here since MainShell
      // never sees a "first entry" for it on app open.
      TutorialService.instance.onTabEntered(TabId.habits);
    });
    TutorialService.instance.pendingTab.addListener(_onPendingTab);
  }

  @override
  void dispose() {
    TutorialService.instance.pendingTab.removeListener(_onPendingTab);
    super.dispose();
  }

  void _onPendingTab() {
    if (TutorialService.instance.pendingTab.value != TabId.habits) return;
    if (!mounted || _firstVisitShown) return;
    _firstVisitShown = true;
    TutorialService.instance.clearPending(TabId.habits);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showFirstVisitTour();
    });
  }

  void _showFirstVisitTour() {
    showCoachMarks(
      context: context,
      targets: habitsFirstVisitTargets(
        context: context,
        fabKey: _fabKey,
        actionsKey: _actionsKey,
      ),
      onSeen: () async {
        // First-visit tour genuinely finished or skipped. Mark the tab as
        // seen immediately so the app never re-shows this tour on restart.
        // The deferred habit-card tip is in-memory-gated and fires as a
        // bonus tip once habits exist in the current session.
        _firstVisitComplete = true;
        await TutorialService.instance.markSeen(TabId.habits);
        _maybeStartDeferred();
      },
    );
  }

  void _maybeStartDeferred() {
    if (!_firstVisitComplete || _deferredShown) return;
    final provider = context.read<HabitProvider>();
    if (provider.habits.isNotEmpty) {
      _showDeferredTour();
    }
    // Else: didChangeDependencies catches the transition when the user
    // adds their first habit.
  }

  void _showDeferredTour() {
    if (_deferredShown) return;
    _deferredShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      showCoachMarks(
        context: context,
        targets: habitsDeferredTargets(
          context: context,
          habitCardKey: _firstHabitKey,
        ),
        onSeen: () {
          // Bonus tip — flag already set in first-visit onSeen. Nothing
          // more to persist.
        },
      );
    });
  }
```

- [ ] **Step 3: Watch habit count for deferred step**

Still inside `_HabitGridScreenState`, add this after `_showDeferredTour`:

```dart
  int _lastHabitCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final count = context.watch<HabitProvider>().habits.length;
    if (count > 0 && _lastHabitCount == 0 && _firstVisitComplete && !_deferredShown) {
      _showDeferredTour();
    }
    _lastHabitCount = count;
  }
```

Note: this works because `context.watch` rebuilds `didChangeDependencies` when the provider notifies.

- [ ] **Step 4: Attach `GlobalKey`s to the widgets**

Change `floatingActionButton: FloatingActionButton(...)` to:

```dart
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        onPressed: () => _showAddHabitDialog(context, provider),
        child: const Icon(Icons.add, size: 28),
      ),
```

Change the `actions:` list in the `AppBar` by wrapping its entire `Row`-equivalent children in a single `Row` with `_actionsKey`. Replace:

```dart
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HabitCalendarScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HabitStatsScreen()),
            ),
          ),
        ],
```

with:

```dart
        actions: [
          Row(
            key: _actionsKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded, size: 22),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HabitCalendarScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded, size: 22),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HabitStatsScreen()),
                ),
              ),
            ],
          ),
        ],
```

- [ ] **Step 5: Attach key to first habit card**

Inside `_buildHabitList`, in the `ReorderableListView.builder`, change the `itemBuilder` so the card for index `0` uses `_firstHabitKey` in addition to its existing key. Replace:

```dart
      itemBuilder: (ctx, i) {
        final habit = habits[i];
        final completed = provider.isHabitCompletedOnDate(habit.id, _selectedDate);
        final streak = provider.streaks[habit.id] ?? 0;

        return _HabitCard(
          key: ValueKey(habit.id),
          habit: habit,
          completed: completed,
          streak: streak,
          onToggle: () => provider.toggleHabitForDate(habit.id, _selectedDate),
          onDelete: () => _confirmDeleteHabit(context, habit, provider),
        );
      },
```

with:

```dart
      itemBuilder: (ctx, i) {
        final habit = habits[i];
        final completed = provider.isHabitCompletedOnDate(habit.id, _selectedDate);
        final streak = provider.streaks[habit.id] ?? 0;

        return KeyedSubtree(
          key: ValueKey(habit.id),
          child: Container(
            // Outer wrapper key is used as the spotlight anchor for the
            // first habit only. Inner ValueKey stays on _HabitCard for
            // ReorderableListView.
            key: i == 0 ? _firstHabitKey : null,
            child: _HabitCard(
              key: ValueKey('card_${habit.id}'),
              habit: habit,
              completed: completed,
              streak: streak,
              onToggle: () => provider.toggleHabitForDate(habit.id, _selectedDate),
              onDelete: () => _confirmDeleteHabit(context, habit, provider),
            ),
          ),
        );
      },
```

- [ ] **Step 6: Verify analyzer**

Run: `flutter analyze lib/screens/habit_tracker/habit_grid_screen.dart`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/screens/habit_tracker/habit_grid_screen.dart
git commit -m "feat(tutorial): wire Habits tab coach marks + deferred card step"
```

---

## Task 9: Wire Fitness tab

**Files:**
- Modify: `lib/screens/fitness_tracker/week_list_screen.dart`

- [ ] **Step 1: Add imports**

At the top of `week_list_screen.dart`, add:

```dart
import '../../services/tutorial_service.dart';
import '../../widgets/tutorial/tutorial_steps.dart';
```

- [ ] **Step 2: Add state fields and tutorial triggers**

In `_WeekListScreenState`, replace the existing `initState` and add the new fields / methods. Replace:

```dart
class _WeekListScreenState extends State<WeekListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<FitnessProvider>().initialize();
    });
  }
```

with:

```dart
class _WeekListScreenState extends State<WeekListScreen> {
  final _fabKey = GlobalKey();
  final _firstWeekKey = GlobalKey();

  bool _firstVisitShown = false;
  bool _firstVisitComplete = false;
  bool _deferredShown = false;
  int _lastWeekCount = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<FitnessProvider>().initialize();
    });
    TutorialService.instance.pendingTab.addListener(_onPendingTab);
  }

  @override
  void dispose() {
    TutorialService.instance.pendingTab.removeListener(_onPendingTab);
    super.dispose();
  }

  void _onPendingTab() {
    if (TutorialService.instance.pendingTab.value != TabId.fitness) return;
    if (!mounted || _firstVisitShown) return;
    _firstVisitShown = true;
    TutorialService.instance.clearPending(TabId.fitness);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showFirstVisitTour();
    });
  }

  void _showFirstVisitTour() {
    showCoachMarks(
      context: context,
      targets: fitnessFirstVisitTargets(
        context: context,
        fabKey: _fabKey,
      ),
      onSeen: () async {
        _firstVisitComplete = true;
        await TutorialService.instance.markSeen(TabId.fitness);
        _maybeStartDeferred();
      },
    );
  }

  void _maybeStartDeferred() {
    if (!_firstVisitComplete || _deferredShown) return;
    final weeks = context.read<FitnessProvider>().weeks;
    if (weeks.isNotEmpty) {
      _showDeferredTour();
    }
  }

  void _showDeferredTour() {
    if (_deferredShown) return;
    _deferredShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      showCoachMarks(
        context: context,
        targets: fitnessDeferredTargets(
          context: context,
          weekCardKey: _firstWeekKey,
        ),
        onSeen: () {
          // Bonus tip — flag already set.
        },
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final count = context.watch<FitnessProvider>().weeks.length;
    if (count > 0 && _lastWeekCount == 0 && _firstVisitComplete && !_deferredShown) {
      _showDeferredTour();
    }
    _lastWeekCount = count;
  }
```

- [ ] **Step 3: Attach `GlobalKey` to FAB**

Change:

```dart
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOptions(context, provider),
        child: const Icon(Icons.add, size: 28),
      ),
```

to:

```dart
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        onPressed: () => _showCreateOptions(context, provider),
        child: const Icon(Icons.add, size: 28),
      ),
```

- [ ] **Step 4: Attach `GlobalKey` to the first week card**

Inside `_buildGroupedList`, only the **first** week in the **first** month group should get `_firstWeekKey`. Replace:

```dart
            ...weeks.map((week) => _buildWeekCard(context, week)),
```

with:

```dart
            ...weeks.asMap().entries.map((entry) {
              final isFirstOverall = i == 0 && entry.key == 0;
              return _buildWeekCard(
                context,
                entry.value,
                keyOverride: isFirstOverall ? _firstWeekKey : null,
              );
            }),
```

Then change the `_buildWeekCard` signature from:

```dart
  Widget _buildWeekCard(BuildContext context, FitnessWeek week) {
```

to:

```dart
  Widget _buildWeekCard(BuildContext context, FitnessWeek week, {Key? keyOverride}) {
```

And change the outermost `GestureDetector` of that method from:

```dart
    return GestureDetector(
      onTap: () => Navigator.push(
```

to:

```dart
    return GestureDetector(
      key: keyOverride,
      onTap: () => Navigator.push(
```

- [ ] **Step 5: Verify analyzer**

Run: `flutter analyze lib/screens/fitness_tracker/week_list_screen.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/screens/fitness_tracker/week_list_screen.dart
git commit -m "feat(tutorial): wire Fitness tab coach marks + deferred week-card step"
```

---

## Task 10: Wire Water tab

**Files:**
- Modify: `lib/screens/water_tracker/water_tracking_screen.dart`

- [ ] **Step 1: Add imports**

At the top of `water_tracking_screen.dart`, add:

```dart
import '../../services/tutorial_service.dart';
import '../../widgets/tutorial/tutorial_steps.dart';
```

- [ ] **Step 2: Add state fields and trigger**

In `_WaterTrackingScreenState`, add these fields near the top (after the animation controllers):

```dart
  final _bottlesKey = GlobalKey();
  final _goalKey = GlobalKey();
  bool _tutorialShown = false;
```

In `initState`, at the end (after the existing `Future.microtask`), add:

```dart
    TutorialService.instance.pendingTab.addListener(_onPendingTab);
```

In `dispose`, before `super.dispose()`, add:

```dart
    TutorialService.instance.pendingTab.removeListener(_onPendingTab);
```

Add the methods inside the state class:

```dart
  void _onPendingTab() {
    if (TutorialService.instance.pendingTab.value != TabId.water) return;
    if (!mounted || _tutorialShown) return;
    _tutorialShown = true;
    TutorialService.instance.clearPending(TabId.water);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showTour();
    });
  }

  void _showTour() {
    showCoachMarks(
      context: context,
      targets: waterTargets(
        context: context,
        bottlesKey: _bottlesKey,
        goalKey: _goalKey,
      ),
      onSeen: () async {
        await TutorialService.instance.markSeen(TabId.water);
      },
    );
  }
```

- [ ] **Step 3: Attach `GlobalKey`s**

**Goal key on tune icon** — in the `AppBar` actions, find:

```dart
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 22),
            onPressed: () => _showSetGoalDialog(context, provider),
          ),
```

and change to:

```dart
          IconButton(
            key: _goalKey,
            icon: const Icon(Icons.tune_rounded, size: 22),
            onPressed: () => _showSetGoalDialog(context, provider),
          ),
```

**Bottles key on the preset row** — the bottle buttons are built by `_buildBottleButtons` which currently starts:

```dart
  Widget _buildBottleButtons(WaterProvider provider) {
    final l = AppLocalizations.of(context);
    return Row(
      children: _bottlePresets.map((preset) {
```

Add `key: _bottlesKey` to that `Row`:

```dart
  Widget _buildBottleButtons(WaterProvider provider) {
    final l = AppLocalizations.of(context);
    return Row(
      key: _bottlesKey,
      children: _bottlePresets.map((preset) {
```

Run: `flutter analyze lib/screens/water_tracker/water_tracking_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/water_tracker/water_tracking_screen.dart
git commit -m "feat(tutorial): wire Water tab coach marks"
```

---

## Task 11: Wire Tools (Settings) tab

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`

Because `SettingsScreen` is currently a `StatelessWidget`, we convert it to `StatefulWidget` to hold `GlobalKey`s, a `ScrollController`, and the tutorial listener.

- [ ] **Step 1: Convert to StatefulWidget and add imports + fields**

At the top of `settings_screen.dart`, add these imports (near the existing imports):

```dart
import '../../services/tutorial_service.dart';
import '../../widgets/tutorial/tutorial_steps.dart';
```

Replace the class declaration:

```dart
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
```

with:

```dart
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _calculatorsKey = GlobalKey();
  final _appleHealthKey = GlobalKey();
  final _backupKey = GlobalKey();
  final _scrollController = ScrollController();
  bool _tutorialShown = false;

  @override
  void initState() {
    super.initState();
    TutorialService.instance.pendingTab.addListener(_onPendingTab);
  }

  @override
  void dispose() {
    TutorialService.instance.pendingTab.removeListener(_onPendingTab);
    _scrollController.dispose();
    super.dispose();
  }

  void _onPendingTab() {
    if (TutorialService.instance.pendingTab.value != TabId.tools) return;
    if (!mounted || _tutorialShown) return;
    _tutorialShown = true;
    TutorialService.instance.clearPending(TabId.tools);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showTour();
    });
  }

  void _showTour() {
    showCoachMarks(
      context: context,
      targets: toolsTargets(
        context: context,
        calculatorsKey: _calculatorsKey,
        appleHealthKey: Platform.isIOS ? _appleHealthKey : null,
        backupKey: _backupKey,
      ),
      onSeen: () async {
        await TutorialService.instance.markSeen(TabId.tools);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
```

- [ ] **Step 2: Attach `ScrollController` to the body `ListView`**

Find the `body: ListView(` near the top of `build()` and change:

```dart
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
```

to:

```dart
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
```

- [ ] **Step 3: Wrap the calculators cluster with `_calculatorsKey`**

The 6 calculator `Container(ListTile)` widgets sit as direct children of the `ListView`, preceded by the `l.calculators` header `Text`. Wrap the header **and** all 6 calculator Containers in a single `Column` with `key: _calculatorsKey`.

Find the line that currently reads `Text(l.calculators, ...)` and the subsequent 6 `Container(...)` blocks (each followed by `SizedBox(height: 8)`, except the last). Replace from that `Text` through the end of the 6th calculator `Container` (Ideal Weight) with:

```dart
          Column(
            key: _calculatorsKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.calculators,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              // ── Preserve the 6 existing calculator Containers here, unchanged ──
            ],
          ),
```

**Important:** keep the 6 `Container` children and their in-between `SizedBox(height: 8)` widgets exactly as they were. Only the outer wrapper is new.

- [ ] **Step 4: Attach `_appleHealthKey` to the Apple Health section**

Find the `if (Platform.isIOS) ...[` block. Change:

```dart
          if (Platform.isIOS) ...[
            const SizedBox(height: 24),
            Text(
              l.appleHealth,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            _HealthSyncTile(),
          ],
```

to:

```dart
          if (Platform.isIOS) ...[
            const SizedBox(height: 24),
            Column(
              key: _appleHealthKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.appleHealth,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                _HealthSyncTile(),
              ],
            ),
          ],
```

- [ ] **Step 5: Attach `_backupKey` to the Backup section**

The Backup section is the **last** section in the ListView. It spans from the `Text(l.backup, ...)` header through the backup-note `Container`. Wrap the header, the export/import Container, the 14px spacer, and the note Container in a single `Column` keyed with `_backupKey`.

Replace this block (everything from the `Text(l.backup,...)` through the closing of the backup-note `Container`):

```dart
          const SizedBox(height: 24),
          Text(
            l.backup,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.upload_file_rounded, color: AppColors.info, size: 20),
                  ),
                  title: Text(l.exportBackup, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(l.exportBackupDesc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  onTap: () => _exportBackup(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.download_rounded, color: AppColors.success, size: 20),
                  ),
                  title: Text(l.importBackup, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(l.importBackupDesc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  onTap: () => _importBackup(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.backupNote,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
```

with this wrapped version (the children are identical — the only change is the enclosing `Column(key: _backupKey, ...)`):

```dart
          const SizedBox(height: 24),
          Column(
            key: _backupKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.backup,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.upload_file_rounded, color: AppColors.info, size: 20),
                      ),
                      title: Text(l.exportBackup, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(l.exportBackupDesc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      onTap: () => _exportBackup(context),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.download_rounded, color: AppColors.success, size: 20),
                      ),
                      title: Text(l.importBackup, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(l.importBackupDesc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      onTap: () => _importBackup(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.backupNote,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
```

- [ ] **Step 6: Add the "Replay tutorial" tile**

At the very end of the `ListView` children (just before the closing `]` and `)` of the `ListView` / `body`), add:

```dart
          const SizedBox(height: 24),
          Text(
            l.tools,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.replay_rounded, size: 20, color: AppColors.accent),
              ),
              title: Text(
                l.tutorialReplayTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                l.tutorialReplaySubtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_left, color: AppColors.textTertiary),
              onTap: () async {
                await TutorialService.instance.resetAllFlags();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.tutorialReplayConfirmSnack)),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
```

- [ ] **Step 7: Verify analyzer**

Run: `flutter analyze lib/screens/settings/settings_screen.dart`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/screens/settings/settings_screen.dart
git commit -m "feat(tutorial): wire Tools tab coach marks + replay control"
```

---

## Task 12: Full-app analyze + build

- [ ] **Step 1: Run analyzer over all changes**

Run: `flutter analyze`
Expected: `No issues found!` (or pre-existing warnings only — zero new errors).

- [ ] **Step 2: Run all tests**

Run: `flutter test`
Expected: all tests pass, including the new `tutorial_service_test.dart`.

- [ ] **Step 3: Debug build**

Run: `flutter build apk --debug` (Android) or `flutter build ios --debug --no-codesign` (iOS).
Expected: build succeeds.

- [ ] **Step 4: Commit (if any fixes were needed)**

If analyzer or tests revealed any issues and you made fixes, commit them:

```bash
git add -A
git commit -m "fix: address analyzer / test issues after tutorial wiring"
```

If nothing needed fixing, skip this commit.

---

## Task 13: Manual smoke test on device/simulator

Run the app on a real simulator or device. Work through the checklist below; note any failures before calling the feature complete.

- [ ] **Step 1: Fresh install — Habits tutorial on app open**

1. Uninstall the app (to clear `SharedPreferences`) or run:
   ```bash
   flutter run
   # then in the running app, tap "Replay tutorial" to simulate first launch
   ```
2. App opens directly to Habits tab.
3. **Expected:** coach mark appears on the FAB (Step 1/2), then on the top-right actions (Step 2/2).
4. Tap "Got it" on the last step.

- [ ] **Step 2: Add a habit → deferred step fires**

1. Tap the FAB, add a habit.
2. **Expected:** after the dialog closes, a single-step coach mark (1/1) appears over the new habit card.
3. Tap "Got it".

- [ ] **Step 3: Switch to Fitness → Fitness first-visit step**

1. Tap the Fitness tab.
2. **Expected:** coach mark 1/1 on the FAB.
3. Tap "Got it".

- [ ] **Step 4: Create a week → deferred Fitness step**

1. Tap FAB → "Current week".
2. Navigate back to week list (the week appears).
3. **Expected:** coach mark 1/1 on the first week card.

- [ ] **Step 5: Switch to Water → 2 coach marks**

1. Tap Water tab.
2. **Expected:** coach mark 1/2 on the bottle presets, then 2/2 on the tune icon.

- [ ] **Step 6: Switch to Tools → calculators → health (iOS) → backup**

1. Tap Tools tab.
2. **Expected (iOS):** coach mark 1/3 on the calculators cluster, 2/3 on Apple Health tile (list should scroll), 3/3 on Backup section.
2. **Expected (Android):** coach mark 1/2 on calculators, 2/2 on Backup.

- [ ] **Step 7: Relaunch the app — no tutorials fire**

1. Fully quit and relaunch.
2. **Expected:** no coach marks on any tab.

- [ ] **Step 8: Replay control**

1. Tools tab → "Replay tutorial" tile → tap it.
2. **Expected:** SnackBar confirmation appears.
3. Leave Tools tab, return to Habits.
4. **Expected:** Habits tutorial fires again from Step 1/2.

- [ ] **Step 9: Skip behavior**

1. While a coach mark is on screen, tap "Skip".
2. **Expected:** overlay dismisses, flag flips. Switching back to that tab does not re-trigger.

- [ ] **Step 10: Tab-switch mid-tutorial does NOT flip flag**

1. Replay tutorials.
2. On Water tab, when the first coach mark is visible, tap a different bottom-nav item (e.g., Habits).
3. **Expected:** overlay dismisses without marking seen.
4. Return to Water tab.
5. **Expected:** Water tutorial fires again from Step 1/2.

**Note on step 10:** Behavior relies on `MainShell`'s `onTap` calling `TutorialService.dismissActive()` before the new tab is built. The service sets `_dismissing = true` and calls `coach.finish()`; `showCoachMarks`'s `onFinish` hook checks `isDismissing` and skips `onSeen`, so the flag stays unset. If this is broken in practice, verify that `_dismissing` is actually checked — the plan wires it through but the package's callback ordering is worth confirming on a real device.

- [ ] **Step 11: Language switch + replay**

1. Tools tab → switch language to English.
2. Tools tab → "Replay tutorial".
3. Go to Habits.
4. **Expected:** coach marks appear in English.

- [ ] **Step 12: Commit any fixes**

If any of the above steps failed, fix and commit per usual TDD/commit discipline. If all pass, no commit needed.

---

## Done

When all tasks are checked off and the manual smoke test passes, the feature is complete. The next logical step is to ship via the existing release flow (`flutter build apk --release` / `flutter build ios --release`).
