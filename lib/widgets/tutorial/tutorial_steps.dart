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
///
/// If [scrollToNextKey] is provided, tapping Next will first scroll that
/// widget into view (for off-screen targets on long lists like Settings),
/// then advance. The target is centered in the viewport so there's room
/// for the tooltip above or below it.
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
  GlobalKey? scrollToNextKey,
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
          onNext: () {
            _advanceWithScroll(controller, scrollToNextKey);
          },
          onSkip: () => controller.skip(),
        ),
      ),
    ],
  );
}

/// Scrolls the next target into view (if any) then advances the tour.
/// Wrapped in a non-async function because `VoidCallback` doesn't accept
/// a `Future<void> Function()`.
void _advanceWithScroll(
  TutorialCoachMarkController controller,
  GlobalKey? scrollToNextKey,
) async {
  final ctx = scrollToNextKey?.currentContext;
  if (ctx != null) {
    await Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }
  controller.next();
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

  // The Tools screen is a scrolling ListView. Each step pre-scrolls the
  // NEXT target into view before advancing, so the spotlight never lands
  // on a clipped / off-screen widget.
  final targets = <TargetFocus>[
    _target(
      identify: 'tools_calculators',
      key: calculatorsKey,
      title: l.tutorialToolsCalculatorsTitle,
      body: l.tutorialToolsCalculatorsBody,
      step: 1,
      total: total,
      align: ContentAlign.bottom,
      scrollToNextKey: hasHealth ? appleHealthKey : backupKey,
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
        scrollToNextKey: backupKey,
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
