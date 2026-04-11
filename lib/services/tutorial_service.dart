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
