import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/fitness_week.dart';
import '../../providers/fitness_provider.dart';
import '../../utils/app_theme.dart';

class NutritionTab extends StatelessWidget {
  final FitnessWeek week;

  const NutritionTab({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final averages = provider.weeklyAverageNutrition;
    final targets = provider.macroTargets;
    final hasTargets = targets['calories']! > 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTargetsCard(context, provider, targets),
        const SizedBox(height: 10),
        if (hasTargets) _buildComparisonCard(context, averages, targets),
        if (hasTargets) const SizedBox(height: 10),
        _buildSummaryCard(context, averages),
        const SizedBox(height: 14),
        ...List.generate(7, (i) {
          final date = week.startDate.add(Duration(days: i));
          final entry = provider.getNutritionForDate(date);
          return _buildDayCard(context, provider, date, i, entry);
        }),
      ],
    );
  }

  Widget _buildTargetsCard(BuildContext context, FitnessProvider provider, Map<String, double> targets) {
    final l = AppLocalizations.of(context);
    final hasTargets = targets['calories']! > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            hasTargets ? Icons.track_changes_rounded : Icons.warning_amber_rounded,
            color: hasTargets ? AppColors.accent : AppColors.warning,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasTargets ? l.dailyTargets : l.noTargetsSet,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (hasTargets)
                  Text(
                    '${targets['calories']!.toStringAsFixed(0)} ${l.calorieSuffix} | '
                    '${l.proteinShort}: ${targets['protein']!.toStringAsFixed(0)} | '
                    '${l.carbsShort}: ${targets['carbs']!.toStringAsFixed(0)} | '
                    '${l.fatsShort}: ${targets['fat']!.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  )
                else
                  Text(
                    l.tapToSetMacroTargets,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showTargetsDialog(context, provider, targets),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_rounded, size: 18, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context, Map<String, double> averages, Map<String, double> targets) {
    final l = AppLocalizations.of(context);
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
            l.actualVsGoal,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          _buildProgressRow(l.calories, averages['calories']!, targets['calories']!),
          const SizedBox(height: 10),
          _buildProgressRow(l.protein, averages['protein']!, targets['protein']!),
          const SizedBox(height: 10),
          _buildProgressRow(l.carbs, averages['carbs']!, targets['carbs']!),
          const SizedBox(height: 10),
          _buildProgressRow(l.fats, averages['fat']!, targets['fat']!),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double actual, double target) {
    if (target <= 0) return const SizedBox.shrink();
    final ratio = (actual / target).clamp(0.0, 1.5);
    final pct = (ratio * 100).toStringAsFixed(0);
    final isOver = ratio > 1.05;
    final isClose = ratio >= 0.9 && ratio <= 1.05;

    Color barColor;
    if (isClose) {
      barColor = AppColors.success;
    } else if (isOver) {
      barColor = AppColors.error;
    } else {
      barColor = AppColors.accent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text(
              '${actual.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} ($pct%)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: barColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, Map<String, double> averages) {
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
            l.weeklyAverage,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statColumn(l.calories, averages['calories']!.toStringAsFixed(0)),
              _statColumn(l.protein, '${averages['protein']!.toStringAsFixed(0)}g'),
              _statColumn(l.carbs, '${averages['carbs']!.toStringAsFixed(0)}g'),
              _statColumn(l.fats, '${averages['fat']!.toStringAsFixed(0)}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accent),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildDayCard(BuildContext context, FitnessProvider provider, DateTime date, int dayIndex, dynamic entry) {
    final l = AppLocalizations.of(context);
    final dayName = l.weekdays[dayIndex];
    final dateStr = DateFormat('d/M').format(date);
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$dayName - $dateStr', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  entry != null
                      ? '${entry.calories.toStringAsFixed(0)} ${l.calorieSuffix} | '
                        '${l.proteinShort}: ${entry.protein.toStringAsFixed(0)} | '
                        '${l.carbsShort}: ${entry.carbs.toStringAsFixed(0)} | '
                        '${l.fatsShort}: ${entry.fat.toStringAsFixed(0)}'
                      : l.notLogged,
                  style: TextStyle(
                    fontSize: 12,
                    color: entry != null ? AppColors.textSecondary : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showNutritionDialog(context, provider, date, entry),
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

  void _showTargetsDialog(BuildContext context, FitnessProvider provider, Map<String, double> targets) {
    final l = AppLocalizations.of(context);
    final caloriesCtrl = TextEditingController(text: targets['calories']! > 0 ? targets['calories']!.toStringAsFixed(0) : '');
    final proteinCtrl = TextEditingController(text: targets['protein']! > 0 ? targets['protein']!.toStringAsFixed(0) : '');
    final carbsCtrl = TextEditingController(text: targets['carbs']! > 0 ? targets['carbs']!.toStringAsFixed(0) : '');
    final fatCtrl = TextEditingController(text: targets['fat']! > 0 ? targets['fat']!.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.dailyMacroTargets),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.macroTargetsNote,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              _numberField(caloriesCtrl, l.caloriesField),
              const SizedBox(height: 10),
              _numberField(proteinCtrl, l.proteinGrams),
              const SizedBox(height: 10),
              _numberField(carbsCtrl, l.carbsGrams),
              const SizedBox(height: 10),
              _numberField(fatCtrl, l.fatsGrams),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              provider.updateMacroTargets(
                calories: double.tryParse(caloriesCtrl.text) ?? 0,
                protein: double.tryParse(proteinCtrl.text) ?? 0,
                carbs: double.tryParse(carbsCtrl.text) ?? 0,
                fat: double.tryParse(fatCtrl.text) ?? 0,
              );
              Navigator.pop(ctx);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  void _showNutritionDialog(BuildContext context, FitnessProvider provider, DateTime date, dynamic entry) {
    final l = AppLocalizations.of(context);
    final caloriesCtrl = TextEditingController(text: entry?.calories.toStringAsFixed(0) ?? '');
    final proteinCtrl = TextEditingController(text: entry?.protein.toStringAsFixed(0) ?? '');
    final carbsCtrl = TextEditingController(text: entry?.carbs.toStringAsFixed(0) ?? '');
    final fatCtrl = TextEditingController(text: entry?.fat.toStringAsFixed(0) ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.nutritionDate(DateFormat('d/M').format(date))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numberField(caloriesCtrl, l.caloriesField),
              const SizedBox(height: 10),
              _numberField(proteinCtrl, l.proteinGrams),
              const SizedBox(height: 10),
              _numberField(carbsCtrl, l.carbsGrams),
              const SizedBox(height: 10),
              _numberField(fatCtrl, l.fatsGrams),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              provider.saveNutritionEntry(
                weekId: week.id,
                date: date,
                calories: double.tryParse(caloriesCtrl.text) ?? 0,
                protein: double.tryParse(proteinCtrl.text) ?? 0,
                carbs: double.tryParse(carbsCtrl.text) ?? 0,
                fat: double.tryParse(fatCtrl.text) ?? 0,
              );
              Navigator.pop(ctx);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
