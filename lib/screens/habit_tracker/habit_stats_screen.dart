import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../utils/app_theme.dart';
import '../../l10n/app_localizations.dart';

class HabitStatsScreen extends StatelessWidget {
  const HabitStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.statistics)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverallDonut(context, provider),
          const SizedBox(height: 16),
          _buildDailyBarChart(context, provider),
          const SizedBox(height: 16),
          _buildHabitRanking(context, provider),
        ],
      ),
    );
  }

  Widget _buildOverallDonut(BuildContext context, HabitProvider provider) {
    final l = AppLocalizations.of(context);
    final rate = provider.overallCompletionRate();
    final completedPct = rate * 100;
    final remainingPct = 100 - completedPct;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            l.monthlyCompletionRate,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    value: completedPct,
                    color: AppColors.accent,
                    title: '${completedPct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      color: AppColors.background,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    radius: 40,
                  ),
                  PieChartSectionData(
                    value: remainingPct > 0 ? remainingPct : 0.01,
                    color: AppColors.surfaceLight,
                    title: '',
                    radius: 35,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppColors.accent, l.completedLabel),
              const SizedBox(width: 20),
              _legendDot(AppColors.surfaceLight, l.remaining),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBarChart(BuildContext context, HabitProvider provider) {
    final l = AppLocalizations.of(context);
    final days = provider.daysInMonth;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.dailyCompletion,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${(rod.toY * 100).toStringAsFixed(0)}%',
                        const TextStyle(color: AppColors.background, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final day = value.toInt() + 1;
                        if (day % 5 == 1 || day == days) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('$day', style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value * 100).toInt()}%',
                          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                barGroups: List.generate(days, (i) {
                  final rate = provider.dailyCompletionRate(i + 1);
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: rate,
                        width: days > 20 ? 5 : 8,
                        color: _barColor(rate),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitRanking(BuildContext context, HabitProvider provider) {
    final l = AppLocalizations.of(context);
    final ranking = provider.habitRanking();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.habitRanking,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ...ranking.asMap().entries.map((entry) {
            final index = entry.key;
            final habit = entry.value.key;
            final rate = entry.value.value;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: index < ranking.length - 1
                      ? const BorderSide(color: AppColors.border, width: 0.5)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: index < 3 ? AppColors.accent : AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (index == 0)
                    const Icon(Icons.emoji_events, color: AppColors.accent, size: 18),
                  if (index == 1)
                    Icon(Icons.emoji_events, color: AppColors.textSecondary, size: 16),
                  if (index == 2)
                    Icon(Icons.emoji_events, color: AppColors.textTertiary, size: 16),
                  if (index > 2) const SizedBox(width: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      habit.name,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    '${(rate * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _barColor(rate),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Color _barColor(double rate) {
    if (rate >= 0.8) return AppColors.accent;
    if (rate >= 0.5) return AppColors.warning;
    return AppColors.error;
  }
}
