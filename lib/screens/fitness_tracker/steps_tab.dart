import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../models/fitness_week.dart';
import '../../providers/fitness_provider.dart';
import '../../utils/app_theme.dart';

class StepsTab extends StatelessWidget {
  final FitnessWeek week;

  const StepsTab({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final avgSteps = provider.weeklyAverageSteps;
    final totalSteps = provider.weeklyTotalSteps;
    final stepGoal = provider.stepGoal;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(context, avgSteps, totalSteps, stepGoal),
        const SizedBox(height: 14),
        if (provider.stepEntries.isNotEmpty) ...[
          _buildChart(context, provider),
          const SizedBox(height: 14),
        ],
        ...List.generate(7, (i) {
          final date = week.startDate.add(Duration(days: i));
          final entry = provider.getStepsForDate(date);
          return _buildDayCard(context, date, i, entry, stepGoal);
        }),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, int avgSteps, int totalSteps, int stepGoal) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            l.stepsSummary,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statColumn(l.dailyAverage, _formatSteps(avgSteps)),
              _statColumn(l.weeklyTotal, _formatSteps(totalSteps)),
              GestureDetector(
                onTap: () => _showGoalDialog(context, stepGoal),
                child: _statColumn(l.stepDailyGoal, _formatSteps(stepGoal), showEdit: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, {bool showEdit = false}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
            if (showEdit) ...[
              const SizedBox(width: 4),
              const Icon(Icons.edit_rounded, size: 14, color: AppColors.textSecondary),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  void _showGoalDialog(BuildContext context, int currentGoal) {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentGoal.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l.setStepGoal, style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l.stepGoalHint,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final goal = int.tryParse(controller.text);
              if (goal != null && goal > 0) {
                context.read<FitnessProvider>().updateStepGoal(goal);
              }
              Navigator.pop(ctx);
            },
            child: Text(l.save, style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, FitnessProvider provider) {
    final l = AppLocalizations.of(context);
    final stepGoal = provider.stepGoal;
    final maxSteps = provider.stepEntries.fold<int>(0, (max, e) => e.steps > max ? e.steps : max);
    final chartMax = [maxSteps, stepGoal].reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: chartMax > 0 ? chartMax : 10000.0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  _formatSteps(rod.toY.toInt()),
                  const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx > 6) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l.weekdaysShort[idx],
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: stepGoal.toDouble(),
                color: AppColors.accent.withValues(alpha: 0.3),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ],
          ),
          barGroups: List.generate(7, (i) {
            final date = week.startDate.add(Duration(days: i));
            final entry = provider.getStepsForDate(date);
            final steps = entry?.steps.toDouble() ?? 0;
            final isToday = _isSameDay(date, DateTime.now());
            final metGoal = steps >= stepGoal;

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: steps,
                  color: metGoal
                      ? AppColors.success
                      : isToday
                          ? AppColors.accent
                          : AppColors.accent.withValues(alpha: 0.5),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, DateTime date, int dayIndex, dynamic entry, int stepGoal) {
    final l = AppLocalizations.of(context);
    final dayName = l.weekdays[dayIndex];
    final dateStr = DateFormat('d/M').format(date);
    final isToday = _isSameDay(date, DateTime.now());
    final steps = entry?.steps ?? 0;
    final metGoal = steps >= stepGoal;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border,
          width: isToday ? 1 : 0.5,
        ),
      ),
      child: Row(
        children: [
          if (isToday)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsetsDirectional.only(end: 8),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$dayName - $dateStr', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  steps > 0 ? '${_formatSteps(steps)} ${l.step}' : l.noData,
                  style: TextStyle(
                    fontSize: 12,
                    color: steps > 0 ? AppColors.textSecondary : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (steps > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: metGoal
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                metGoal ? Icons.check_circle_rounded : Icons.directions_walk_rounded,
                size: 18,
                color: metGoal ? AppColors.success : AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
