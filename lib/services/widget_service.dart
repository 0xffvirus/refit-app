import 'package:home_widget/home_widget.dart';
import '../providers/habit_provider.dart';
import '../providers/water_provider.dart';

const _appGroupId = 'group.com.habitgame.widget';
const _androidWidgetName = 'HabitGameWidget';
const _iOSWidgetName = 'HabitGameWidget';

class WidgetService {
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateWidgetData({
    required HabitProvider habitProvider,
    required WaterProvider waterProvider,
  }) async {
    final now = DateTime.now();

    // Habits
    final totalHabits = habitProvider.habits.length;
    final completedHabits = habitProvider.completedCountForDate(now);
    final maxStreak = habitProvider.streaks.values.fold<int>(0, (a, b) => a > b ? a : b);

    // Water
    final waterMl = waterProvider.totalMl;
    final waterGoal = waterProvider.dailyGoalMl;

    await Future.wait([
      HomeWidget.saveWidgetData('completed_habits', completedHabits),
      HomeWidget.saveWidgetData('total_habits', totalHabits),
      HomeWidget.saveWidgetData('max_streak', maxStreak),
      HomeWidget.saveWidgetData('water_ml', waterMl),
      HomeWidget.saveWidgetData('water_goal', waterGoal),
      HomeWidget.saveWidgetData('last_updated', now.toIso8601String()),
    ]);

    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: _iOSWidgetName,
    );
  }
}
