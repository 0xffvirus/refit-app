import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../utils/app_theme.dart';
import '../../l10n/app_localizations.dart';

class HabitCalendarScreen extends StatelessWidget {
  const HabitCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final daysInMonth = provider.daysInMonth;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.monthlyCalendar)),
      body: Column(
        children: [
          _buildMonthSelector(context, provider),
          _buildOverallRate(context, provider),
          const SizedBox(height: 8),
          Expanded(child: _buildCalendarGrid(context, provider, daysInMonth)),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, HabitProvider provider) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(Icons.chevron_left, () {
            int m = provider.selectedMonth - 1;
            int y = provider.selectedYear;
            if (m < 1) { m = 12; y--; }
            provider.setMonth(y, m);
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '${l.months[provider.selectedMonth - 1]} ${provider.selectedYear}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _navButton(Icons.chevron_right, () {
            int m = provider.selectedMonth + 1;
            int y = provider.selectedYear;
            if (m > 12) { m = 1; y++; }
            provider.setMonth(y, m);
          }),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
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

  Widget _buildOverallRate(BuildContext context, HabitProvider provider) {
    final l = AppLocalizations.of(context);
    final rate = provider.overallCompletionRate();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.completionRate,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                Text(
                  '${(rate * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 6,
                backgroundColor: AppColors.surfaceLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, HabitProvider provider, int daysInMonth) {
    final l = AppLocalizations.of(context);
    final habits = provider.habits;
    if (habits.isEmpty) {
      return Center(
        child: Text(l.noHabits, style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    final firstDayWeekday = DateTime(provider.selectedYear, provider.selectedMonth, 1).weekday % 7;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: l.weekdaysShort
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: firstDayWeekday + daysInMonth,
              itemBuilder: (ctx, i) {
                if (i < firstDayWeekday) return const SizedBox.shrink();
                final day = i - firstDayWeekday + 1;
                final rate = provider.dailyCompletionRate(day);
                final isToday = _isToday(provider.selectedYear, provider.selectedMonth, day);

                return Container(
                  decoration: BoxDecoration(
                    color: rate > 0
                        ? AppColors.accent.withValues(alpha: 0.1 + (rate * 0.4))
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(color: AppColors.accent, width: 2)
                        : Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: rate >= 0.8 ? AppColors.background : AppColors.textPrimary,
                        ),
                      ),
                      if (rate > 0)
                        Text(
                          '${(rate * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 9,
                            color: rate >= 0.8 ? AppColors.background.withValues(alpha: 0.7) : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(int year, int month, int day) {
    final now = DateTime.now();
    return now.year == year && now.month == month && now.day == day;
  }
}
