import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../l10n/app_localizations.dart';
import '../../services/tutorial_service.dart';
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
///
/// [beforeShowTarget] is called (and awaited) BEFORE the spotlight moves
/// to each target — from both Next-button advancement AND target-tap
/// advancement. Use it to scroll the target into view on long scrolling
/// screens like Settings. The callback receives the `identify` string of
/// the target about to be shown.
void showCoachMarks({
  required BuildContext context,
  required List<TargetFocus> targets,
  required VoidCallback onSeen,
  FutureOr<void> Function(String identify)? beforeShowTarget,
}) {
  final coach = TutorialCoachMark(
    targets: targets,
    colorShadow: Colors.black,
    opacityShadow: 0.75,
    paddingFocus: 8,
    hideSkip: true, // we render our own skip inside the tooltip
    beforeFocus: beforeShowTarget == null
        ? null
        : (target) async {
            final id = target.identify?.toString();
            if (id != null) {
              await beforeShowTarget(id);
            }
          },
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

  // The Tools screen is a scrolling ListView. Scrolling the upcoming
  // target into view is handled by `beforeShowTarget` on the caller side
  // (see `_showTour` in settings_screen.dart) — that hook fires both on
  // Next-button advance and on target-tap advance.
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
