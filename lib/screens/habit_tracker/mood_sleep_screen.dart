import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../utils/app_theme.dart';
import '../../l10n/app_localizations.dart';

const _moodEmojis = ['', '😞', '😕', '😐', '🙂', '😄'];

class MoodSleepScreen extends StatelessWidget {
  final DateTime selectedDate;
  const MoodSleepScreen({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final l = AppLocalizations.of(context);
    final isCurrentMonth = provider.selectedYear == selectedDate.year &&
        provider.selectedMonth == selectedDate.month;

    return Scaffold(
      appBar: AppBar(title: Text(l.moodAndSleep)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isCurrentMonth) _buildTodayMood(context, provider, selectedDate),
          if (isCurrentMonth) const SizedBox(height: 12),
          if (isCurrentMonth) _buildTodaySleep(context, provider, selectedDate),
          if (isCurrentMonth) const SizedBox(height: 20),
          _buildSummaryRow(context, provider),
          const SizedBox(height: 16),
          _buildMoodChart(context, provider),
          const SizedBox(height: 16),
          _buildSleepChart(context, provider),
        ],
      ),
    );
  }

  Widget _buildTodayMood(BuildContext context, HabitProvider provider, DateTime today) {
    final l = AppLocalizations.of(context);
    final log = provider.getDailyLogForDay(today.day);
    final currentMood = log?.mood ?? 0;

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
          Row(
            children: [
              const Icon(Icons.emoji_emotions_rounded, size: 20, color: AppColors.mood),
              const SizedBox(width: 8),
              Text(
                l.howAreYouToday,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (currentMood > 0)
                Text(_moodEmojis[currentMood], style: const TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (i) {
              final mood = i + 1;
              final isSelected = currentMood == mood;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _saveMoodSleep(context, provider, today, mood, log?.sleepHours ?? 7),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.mood.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.mood : AppColors.border,
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(_moodEmojis[mood], style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(
                          l.moodLabels[mood],
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? AppColors.mood : AppColors.textTertiary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySleep(BuildContext context, HabitProvider provider, DateTime today) {
    final l = AppLocalizations.of(context);
    final log = provider.getDailyLogForDay(today.day);
    final sleepHours = log?.sleepHours ?? 7.0;

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
          Row(
            children: [
              const Icon(Icons.bedtime_rounded, size: 20, color: AppColors.sleep),
              const SizedBox(width: 8),
              Text(
                l.sleepHours,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                sleepHours.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sleep,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                l.hour,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.sleep,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.sleep,
              overlayColor: AppColors.sleep.withValues(alpha: 0.15),
              trackHeight: 6,
            ),
            child: Slider(
              value: sleepHours,
              min: 0,
              max: 14,
              divisions: 28,
              label: '${sleepHours.toStringAsFixed(1)} ${l.hour}',
              onChanged: (value) => _saveMoodSleep(context, provider, today, log?.mood ?? 3, value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('0', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(l.goalTarget8, style: const TextStyle(fontSize: 10, color: AppColors.accent)),
                ),
                const Text('14', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, HabitProvider provider) {
    final l = AppLocalizations.of(context);
    final logs = provider.dailyLogs;
    if (logs.isEmpty) return const SizedBox.shrink();

    final avgMood = logs.fold<double>(0, (a, l) => a + l.mood) / logs.length;
    final avgSleep = logs.fold<double>(0, (a, l) => a + l.sleepHours) / logs.length;
    final bestMood = logs.fold<int>(0, (a, l) => l.mood > a ? l.mood : a);
    final daysLogged = logs.length;

    return Row(
      children: [
        Expanded(child: _summaryCard(l.average, _moodEmojis[avgMood.round().clamp(1, 5)], AppColors.mood)),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard(l.sleep, '${avgSleep.toStringAsFixed(1)}h', AppColors.sleep)),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard(l.bestMood, _moodEmojis[bestMood.clamp(1, 5)], AppColors.accent)),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard(l.days, '$daysLogged', AppColors.textPrimary)),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _saveMoodSleep(BuildContext context, HabitProvider provider, DateTime date, int mood, double sleepHours) {
    provider.saveDailyLog(date: date, mood: mood, sleepHours: sleepHours);
  }

  Widget _buildMoodChart(BuildContext context, HabitProvider provider) {
    final l = AppLocalizations.of(context);
    final logs = provider.dailyLogs;
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(Icons.emoji_emotions_outlined, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(l.noMoodData, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(l.logMoodDaily, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
      );
    }

    final sortedLogs = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    final spots = sortedLogs.map((l) => FlSpot(l.date.day.toDouble(), l.mood.toDouble())).toList();

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
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, size: 18, color: AppColors.mood),
              const SizedBox(width: 8),
              Text(l.moodChange, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.mood,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.mood,
                        strokeWidth: 2,
                        strokeColor: AppColors.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.mood.withValues(alpha: 0.15),
                          AppColors.mood.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 5 == 1) {
                          return Text('${value.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.textTertiary));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i >= 1 && i <= 5) {
                          return Text(_moodEmojis[i], style: const TextStyle(fontSize: 14));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepChart(BuildContext context, HabitProvider provider) {
    final l = AppLocalizations.of(context);
    final logs = provider.dailyLogs;
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(Icons.bedtime_outlined, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(l.noSleepData, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(l.logSleepDaily, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
      );
    }

    final sortedLogs = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    final spots = sortedLogs.map((l) => FlSpot(l.date.day.toDouble(), l.sleepHours)).toList();
    final avgSleep = sortedLogs.fold<double>(0, (a, l) => a + l.sleepHours) / sortedLogs.length;

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
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, size: 18, color: AppColors.sleep),
              const SizedBox(width: 8),
              Text(l.sleepHours, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sleep.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l.averageSleep(avgSleep.toStringAsFixed(1)),
                  style: const TextStyle(fontSize: 11, color: AppColors.sleep),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 14,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.sleep,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.sleep,
                        strokeWidth: 2,
                        strokeColor: AppColors.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.sleep.withValues(alpha: 0.15),
                          AppColors.sleep.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 8,
                      color: AppColors.accent.withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) => l.goalTarget8Arabic,
                        style: TextStyle(fontSize: 10, color: AppColors.accent.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 5 == 1) {
                          return Text('${value.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.textTertiary));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 2 == 0) {
                          return Text('${value.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.textTertiary));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
