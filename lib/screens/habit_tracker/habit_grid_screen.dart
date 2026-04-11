import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../utils/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'habit_stats_screen.dart';
import 'mood_sleep_screen.dart';
import 'habit_calendar_screen.dart';

class HabitGridScreen extends StatefulWidget {
  const HabitGridScreen({super.key});

  @override
  State<HabitGridScreen> createState() => _HabitGridScreenState();
}

class _HabitGridScreenState extends State<HabitGridScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<HabitProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.habitTracking),
        leading: IconButton(
          icon: const Icon(Icons.nightlight_round, size: 22),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MoodSleepScreen(selectedDate: _selectedDate)),
          ),
        ),
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
      ),
      body: Column(
        children: [
          _buildDateStrip(provider, theme),
          _buildDayProgress(provider, theme),
          Expanded(child: _buildHabitList(provider, theme)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context, provider),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildDateStrip(HabitProvider provider, ThemeData theme) {
    final l = AppLocalizations.of(context);
    final today = DateTime.now();
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navArrow(Icons.chevron_left, () {
                  final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
                  // Go to Saturday (last day) of previous week
                  setState(() => _selectedDate = startOfWeek.subtract(const Duration(days: 1)));
                  _syncProviderMonth(provider);
                }),
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = today);
                    _syncProviderMonth(provider);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _isToday(_selectedDate) ? l.today : _formatFullDate(_selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                _navArrow(Icons.chevron_right, () {
                  final endOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7)).add(const Duration(days: 6));
                  // Go to Sunday (first day) of next week
                  setState(() => _selectedDate = endOfWeek.add(const Duration(days: 1)));
                  _syncProviderMonth(provider);
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(7, (i) {
                final date = startOfWeek.add(Duration(days: i));
                final isSelected = _isSameDay(date, _selectedDate);
                final isTodayDate = _isSameDay(date, today);
                final completedCount = provider.completedCountForDate(date);
                final totalHabits = provider.habits.length;
                final allDone = totalHabits > 0 && completedCount == totalHabits;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = date);
                      _syncProviderMonth(provider);
                    },
                    child: Container(
                      height: 76,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: isTodayDate && !isSelected
                            ? Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.5)
                            : Border.all(color: isSelected ? Colors.transparent : AppColors.border, width: 0.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l.weekdaysShort[date.weekday % 7],
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? AppColors.background : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.background : AppColors.textPrimary,
                            ),
                          ),
                          if (totalHabits > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.background.withValues(alpha: allDone ? 1 : 0.4)
                                    : allDone
                                        ? AppColors.accent
                                        : completedCount > 0
                                            ? AppColors.accent.withValues(alpha: 0.4)
                                            : Colors.transparent,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildDayProgress(HabitProvider provider, ThemeData theme) {
    final l = AppLocalizations.of(context);
    final habits = provider.habits;
    if (habits.isEmpty) return const SizedBox.shrink();

    final completed = provider.completedCountForDate(_selectedDate);
    final total = habits.length;
    final rate = total > 0 ? completed / total : 0.0;
    final maxStreak = provider.streaks.values.fold<int>(0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '$completed / $total',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l.completed,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (maxStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, size: 16, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        '$maxStreak',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 6,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(
                rate >= 1.0 ? AppColors.success : AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitList(HabitProvider provider, ThemeData theme) {
    final l = AppLocalizations.of(context);
    final habits = provider.habits;

    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_rounded, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              l.noHabitsHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: habits.length,
      onReorder: (oldIndex, newIndex) {
        provider.reorderHabits(oldIndex, newIndex);
      },
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
    );
  }

  void _syncProviderMonth(HabitProvider provider) {
    if (provider.selectedYear != _selectedDate.year || provider.selectedMonth != _selectedDate.month) {
      provider.setMonth(_selectedDate.year, _selectedDate.month);
    }
  }

  void _showAddHabitDialog(BuildContext context, HabitProvider provider) {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.addNewHabit),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l.habitName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                provider.addHabit(name);
                Navigator.pop(ctx);
              }
            },
            child: Text(l.add),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteHabit(BuildContext context, Habit habit, HabitProvider provider) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteHabit),
        content: Text(l.confirmDeleteHabit(habit.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              provider.removeHabit(habit.id);
              Navigator.pop(ctx);
            },
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final l = AppLocalizations.of(context);
    final dayName = l.weekdays[date.weekday % 7];
    return '$dayName ${date.day}/${date.month}';
  }

  bool _isToday(DateTime date) => _isSameDay(date, DateTime.now());

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final bool completed;
  final int streak;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _HabitCard({
    super.key,
    required this.habit,
    required this.completed,
    required this.streak,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${habit.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: completed ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border,
            width: completed ? 1 : 0.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: completed ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: completed ? AppColors.accent : AppColors.textTertiary,
                      width: 2,
                    ),
                  ),
                  child: completed
                      ? const Icon(Icons.check, size: 18, color: AppColors.background)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    habit.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration: completed ? TextDecoration.lineThrough : null,
                      color: completed ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (streak > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentDim,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, size: 14, color: AppColors.accent),
                        const SizedBox(width: 2),
                        Text(
                          '$streak',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                const Icon(Icons.drag_handle, color: AppColors.textTertiary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
