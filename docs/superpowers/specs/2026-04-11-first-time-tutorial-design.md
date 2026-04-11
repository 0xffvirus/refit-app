# First-Time User Tutorial — Design Spec

**Date:** 2026-04-11
**Status:** Approved for planning
**Scope:** Add a coach-mark-based tutorial that runs the first time a user visits each of the app's 4 tabs.

---

## 1. Goal

Introduce first-time users to the app's most important features through short, in-context coach marks (spotlight + tooltip) that appear on the real UI. The tutorial fires once per tab on first visit, is skippable per tab, and can be replayed from the Tools tab.

## 2. Scope

In scope:

- Coach marks on 4 tabs: Habits, Fitness, Water, Tools.
- Per-tab first-visit detection using `SharedPreferences` flags.
- Replay control in the Tools tab.
- Arabic (primary) and English localized strings.
- Empty-state handling for Habits and Fitness (deferred step).
- iOS vs Android difference for the Apple Health step.

Out of scope:

- Interactive walkthroughs that force the user to perform the action.
- Onboarding carousel shown before the app.
- Tutorials on any screen other than the 4 tab root screens (no coach marks inside week detail, mood/sleep, calendar, stats, or calculator screens).
- Analytics / telemetry of tutorial completion.

## 3. Approach

Use the `tutorial_coach_mark` Flutter package with a custom tooltip builder to match the app's dark theme and neon-green accent (`AppColors.accent` #CDFF00). A thin `TutorialService` wraps the package with first-launch flag management and per-tab step registration.

**Why the package over custom:** saves ~400 lines of overlay / positioning / scroll-into-view code, handles RTL tooltip anchoring natively, and is actively maintained. The cost is one dependency.

## 4. Architecture

### 4.1 New files

```
lib/services/tutorial_service.dart            # flag management, step coordination
lib/widgets/tutorial/tutorial_steps.dart       # step definitions per tab
lib/widgets/tutorial/tutorial_theme.dart       # custom neon-green tooltip builder
```

### 4.2 Modified files

- `pubspec.yaml` — add `tutorial_coach_mark: ^1.2.x` (verify latest compatible version at implementation time).
- `lib/main.dart` — `MainShell` tracks previous tab index; on change, calls `TutorialService.onTabEntered(tabId)`.
- `lib/screens/habit_tracker/habit_grid_screen.dart` — attach `GlobalKey`s to FAB, first `_HabitCard`, and top-right action icons. Trigger tutorial post-frame in `initState` (this is the default landing tab, so it isn't entered via a tab switch).
- `lib/screens/fitness_tracker/week_list_screen.dart` — attach `GlobalKey` to FAB and to the first week card (once any week exists).
- `lib/screens/water_tracker/water_tracking_screen.dart` — attach `GlobalKey`s to the bottle preset row and to the tune icon.
- `lib/screens/settings/settings_screen.dart` — wrap the calculators cluster in a `Column` with a `GlobalKey`; attach `GlobalKey`s to the Apple Health tile and the Backup section. Add a "Replay tutorial" `ListTile`. Pass a `ScrollController` to the existing `ListView` so the service can scroll targets into view.
- `lib/l10n/app_localizations.dart` — add Arabic + English strings listed in §6.

### 4.3 State storage

Four booleans in `SharedPreferences`:

```
tutorial_habits_seen
tutorial_fitness_seen
tutorial_water_seen
tutorial_tools_seen
```

Default `false`. Flipped to `true` when the user finishes or skips a tab's tutorial. The "Replay tutorial" action resets all four to `false`.

### 4.4 `TutorialService` responsibilities

1. Load and cache the four flags at app startup.
2. Expose `shouldShowFor(TabId)` and `markSeen(TabId)`.
3. Expose `onTabEntered(TabId)` — called from `MainShell` when the selected index changes. Looks up the target screen's registered steps and shows them via `tutorial_coach_mark` if the flag is unset.
4. Expose `resetAllFlags()` for the Replay action.
5. Hold a `ValueNotifier<TabId?>` or equivalent so target screens can rebuild when their registered `GlobalKey`s become available (needed for deferred Habits/Fitness step 2).
6. Dismiss the current tutorial overlay without flipping the flag if the user switches tabs mid-tutorial.

### 4.5 `IndexedStack` trigger handling

All 4 screens build eagerly inside `MainShell`'s `IndexedStack`, so `initState` fires at app launch for every tab — it cannot be used alone to mean "first visit."

Solution:

- `MainShell` tracks the previous `_currentIndex`. When the user taps a nav item, it calls `TutorialService.onTabEntered(newTabId)` after `setState`.
- The **Habits tab** is an exception because it is the default landing tab and is never "entered" via a nav tap on first launch. `HabitGridScreen.initState` calls `TutorialService.onTabEntered(TabId.habits)` in a post-frame callback so the Habits tutorial fires on app open.

## 5. Tutorial content

### 5.1 Habits tab (3 steps)

| # | Target | Arabic | English |
|---|---|---|---|
| 1 | FAB (+) | **أضف أول عادة** — اضغط هنا لإنشاء عادة يومية تريد متابعتها | **Add your first habit** — Tap here to create a daily habit you want to track |
| 2 | First `_HabitCard` (deferred, see §7.1) | **تتبّع تقدّمك** — اضغط على العادة لتعليمها كمُنجَزة، واسحبها لليسار لحذفها | **Track your progress** — Tap a habit to mark it done, swipe left to delete |
| 3 | Calendar + stats icons (top-right) | **شوف سجلّك** — التقويم والإحصائيات توضّح لك تقدّمك عبر الوقت | **See your history** — Calendar and stats show your progress over time |

### 5.2 Fitness tab (2 steps)

| # | Target | Arabic | English |
|---|---|---|---|
| 1 | FAB (+) | **ابدأ أسبوعك** — أنشئ أسبوع تدريب لتسجيل تغذيتك ووزنك وقياساتك | **Start your week** — Create a training week to log nutrition, weight, and measurements |
| 2 | First week card (deferred, see §7.2) | **كل شيء في مكانه** — افتح الأسبوع لتسجّل التغذية، الوزن، الخطوات، التقييم، والقياسات | **Everything in one place** — Open a week to log nutrition, weight, steps, assessment, and measurements |

### 5.3 Water tab (2 steps)

| # | Target | Arabic | English |
|---|---|---|---|
| 1 | Bottle preset row | **سجّل الماء بسرعة** — اضغط على زجاجة لإضافة كمية الماء فوراً | **Log water fast** — Tap a bottle to instantly add water |
| 2 | Tune icon (top-right) | **حدّد هدفك اليومي** — اضبط كمية الماء المطلوبة كل يوم من هنا | **Set your daily goal** — Adjust your daily water target here |

### 5.4 Tools tab (3 steps iOS, 2 steps Android)

| # | Target | Arabic | English |
|---|---|---|---|
| 1 | Calculators section (header + all 6 tiles wrapped in a `Column` with `GlobalKey`) | **حاسبات جاهزة** — 6 حاسبات تساعدك: الماء، الماكروز، BMI، 1RM، نسبة الدهون، والوزن المثالي | **Built-in calculators** — 6 calculators to help you: water, macros, BMI, 1RM, body fat, and ideal weight |
| 2 *(iOS only)* | Apple Health sync tile | **مزامنة Apple Health** — فعّل المزامنة لاستيراد وزنك وخطواتك تلقائياً | **Apple Health sync** — Enable to auto-import your weight and steps |
| 3 | Backup section | **احفظ بياناتك** — صدّر نسخة احتياطية حتى لا تفقد تقدّمك أبداً | **Back up your data** — Export a backup so you never lose your progress |

**Totals:** iOS = 10 steps across all tabs. Android = 9 steps.

## 6. Localization keys (to add to `AppLocalizations`)

Group under a `tutorial*` prefix, for example:

```
tutorialHabitsAddTitle, tutorialHabitsAddBody
tutorialHabitsTrackTitle, tutorialHabitsTrackBody
tutorialHabitsHistoryTitle, tutorialHabitsHistoryBody
tutorialFitnessWeekTitle, tutorialFitnessWeekBody
tutorialFitnessOpenTitle, tutorialFitnessOpenBody
tutorialWaterLogTitle, tutorialWaterLogBody
tutorialWaterGoalTitle, tutorialWaterGoalBody
tutorialToolsCalculatorsTitle, tutorialToolsCalculatorsBody
tutorialToolsHealthTitle, tutorialToolsHealthBody
tutorialToolsBackupTitle, tutorialToolsBackupBody
tutorialSkip                           # "تخطّي" / "Skip"
tutorialNext                           # "التالي" / "Next"
tutorialDone                           # "تمام" / "Got it"
tutorialReplayTitle                    # "إعادة عرض الشرح" / "Replay tutorial"
tutorialReplaySubtitle                 # "شاهد جولة المميزات من جديد" / "See the feature tour again"
tutorialReplayConfirmSnack             # "سيتم عرض الشرح عند زيارة كل قسم" / "Tutorial will show when you visit each tab"
```

Both Arabic and English values provided at implementation time; text is taken from §5.

## 7. Edge cases

### 7.1 Habits tab — empty state

On first launch the user has no habits, so there is no `_HabitCard` to target for step 2.

**Behavior:**

- On first visit: show the FAB step as "1/2" and the calendar/stats icons step as "2/2". Only two steps appear on the first visit because the third (habit-card) step is deferred.
- Watch `HabitProvider.habits` via a `ValueNotifier` exposed by `TutorialService`.
- The first time `habits.isNotEmpty` while `tutorial_habits_seen == false`, show the deferred habit-card step as a **standalone single-step tour** (no counter, or shown as "1/1"). It is a separate tutorial session from the first two.
- After the deferred step is shown (or skipped), flip `tutorial_habits_seen` to `true`.

This keeps the step counter honest: the user never sees "2/3" followed by nothing, and the deferred tip arrives at the moment it becomes useful.

### 7.2 Fitness tab — empty state

Same pattern as Habits:

- On first visit: show only the FAB step as "1/1" (since it is the only step until a week exists).
- Watch `FitnessProvider.weeks`. When `weeks.isNotEmpty` and `tutorial_fitness_seen == false`, show the week-card step as a standalone single-step tour.
- Flip `tutorial_fitness_seen` to `true` after the deferred step is shown or skipped.

### 7.3 Android has no Apple Health

Wrap the Apple Health step in `if (Platform.isIOS)` when building the tool tab's step list. On Android the Tools tutorial is just `calculators → backup`. The `tutorial_tools_seen` flag flips after the Backup step on both platforms.

### 7.4 Tab switching mid-tutorial

If the user taps another bottom nav item while a tutorial overlay is visible:

- The current overlay dismisses immediately.
- The current tab's flag is **not** flipped.
- On a future return to that tab, the tutorial fires again from step 1.

This prevents the user from being trapped in a tutorial and lets them explore freely.

### 7.5 Scrolling to off-screen targets

The Apple Health tile and Backup section on the Tools tab are below the fold. The `tutorial_coach_mark` package supports `Targets.withAlignSkip` and accepts a target that scrolls into view before showing, but we also keep a `ScrollController` on the Settings `ListView` as a fallback: before firing a step whose target is not visible, `TutorialService` calls `Scrollable.ensureVisible` on the `GlobalKey`'s `BuildContext`.

### 7.6 Language switching mid-tutorial

Tutorial strings come from `AppLocalizations`, so switching language via the Tools tab language toggle is picked up the next time the tutorial fires. In-flight tutorials are not re-rendered on locale change — this is acceptable given how rare the scenario is.

## 8. Tooltip styling

### 8.1 Container

- Background: `AppColors.surface`
- Border: 1.5px `AppColors.accent` (#CDFF00)
- Corner radius: 16
- Padding: 16 horizontal, 14 vertical
- Shadow: soft, 8px blur, 20% black

### 8.2 Text

- Title: bold 16sp, `AppColors.textPrimary`
- Body: 14sp, `AppColors.textSecondary`, 6px top margin

### 8.3 Spotlight cutout

- Shape: rounded rectangle, radius 12
- Dim overlay: 75% black
- Padding around target: 8px

### 8.4 Footer row

Horizontal row inside the tooltip:

- Skip button: `TextButton`, text "تخطّي" / "Skip", `AppColors.textSecondary`.
- Step counter: "current / total" (per tab), 12sp `AppColors.textTertiary`, center.
- Next button: `FilledButton`, accent background, `AppColors.background` text. Label "التالي" / "Next" except on the final step of a tab, where it becomes "تمام" / "Got it".

### 8.5 RTL

The package respects the ambient `Directionality`, which is forced to RTL in Arabic mode by `main.dart`. Tooltip text alignment and footer row mirror automatically.

## 9. Replay control

New `ListTile` added to the Tools tab, placed near the bottom of the screen (below Backup section, above "About" if it exists):

- Icon: `Icons.replay_rounded`
- Title: localized "Replay tutorial"
- Subtitle: localized "See the feature tour again"
- `onTap`: calls `TutorialService.resetAllFlags()` and shows a SnackBar with `tutorialReplayConfirmSnack` text.

No navigation happens — the user must switch tabs themselves to see the tutorials again. Switching away from and back to Tools will retrigger the Tools tutorial.

## 10. Testing plan

Manual testing checklist (no automated widget tests required for tutorial visuals):

1. Fresh install → Habits tab tutorial fires automatically (steps 1 and 3).
2. Add a habit → deferred step 2 fires.
3. Switch to Fitness tab → Fitness step 1 fires.
4. Create a week → step 2 fires.
5. Switch to Water tab → water tutorial fires (both steps).
6. Switch to Tools tab → tools tutorial fires (3 steps on iOS, 2 on Android), with auto-scroll to Apple Health / Backup.
7. Reopen app → no tutorials fire (flags persisted).
8. Tap "Replay tutorial" in Tools → all tutorials fire again on next tab visit.
9. Tap Skip on any tutorial → overlay dismisses, flag flips, tutorial does not reappear.
10. Tap a different bottom nav tab mid-tutorial → overlay dismisses, flag unchanged, tutorial reappears on return.
11. Switch language mid-session then trigger tutorial → strings appear in new language.
12. Run on Android → Apple Health step is absent, Backup step is final.

## 11. Open questions

None. All decisions ratified in the brainstorming session.

## 12. Next step

Invoke the `superpowers:writing-plans` skill to produce a step-by-step implementation plan.
