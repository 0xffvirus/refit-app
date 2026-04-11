import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/fitness_week.dart';
import '../../providers/fitness_provider.dart';
import '../../utils/app_theme.dart';

class WeightTab extends StatelessWidget {
  final FitnessWeek week;

  const WeightTab({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final provider = context.watch<FitnessProvider>();
    final avgWeight = provider.weeklyAverageWeight;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (avgWeight > 0)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 0.5),
            ),
            child: Column(
              children: [
                Text(
                  l.weeklyAverageWeight,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  avgWeight.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
                Text(
                  l.kg,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (provider.weightEntries.length >= 2) _buildWeightChart(context, provider),
        const SizedBox(height: 12),
        ...List.generate(7, (i) {
          final date = week.startDate.add(Duration(days: i));
          final entry = provider.getWeightForDate(date);
          return _buildDayTile(context, provider, date, i, entry);
        }),
      ],
    );
  }

  Widget _buildWeightChart(BuildContext context, FitnessProvider provider) {
    final l = AppLocalizations.of(context);
    final entries = [...provider.weightEntries]..sort((a, b) => a.date.compareTo(b.date));
    final spots = entries.asMap().entries.map(
      (e) => FlSpot(e.key.toDouble(), e.value.weight),
    ).toList();

    final minW = entries.fold<double>(999, (a, e) => e.weight < a ? e.weight : a);
    final maxW = entries.fold<double>(0, (a, e) => e.weight > a ? e.weight : a);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: (minW - 1).floorToDouble(),
            maxY: (maxW + 1).ceilToDouble(),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.accent,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.accent,
                    strokeWidth: 0,
                  ),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i >= 0 && i < entries.length) {
                      return Text(
                        l.weekdaysShort[entries[i].date.weekday % 7],
                        style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10, color: AppColors.textTertiary));
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
    );
  }

  Widget _buildDayTile(BuildContext context, FitnessProvider provider, DateTime date, int dayIndex, dynamic entry) {
    final l = AppLocalizations.of(context);
    final dayName = l.weekdays[dayIndex];
    final isToday = _isSameDay(date, DateTime.now());

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dayName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              Text(DateFormat('d/M').format(date), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          if (entry != null)
            Text(
              '${entry.weight.toStringAsFixed(1)} ${l.kg}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accent),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showWeightDialog(context, provider, date, entry),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                entry != null ? Icons.edit_rounded : Icons.add_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context, FitnessProvider provider, DateTime date, dynamic entry) {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: entry?.weight.toStringAsFixed(1) ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.weightDate(DateFormat('d/M').format(date))),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(hintText: l.weightHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final weight = double.tryParse(ctrl.text);
              if (weight != null && weight > 0) {
                provider.saveWeightEntry(weekId: week.id, date: date, weight: weight);
                Navigator.pop(ctx);
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
