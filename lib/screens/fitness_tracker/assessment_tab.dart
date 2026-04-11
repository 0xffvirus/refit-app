import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/fitness_week.dart';
import '../../providers/fitness_provider.dart';
import '../../utils/app_theme.dart';

class AssessmentTab extends StatefulWidget {
  final FitnessWeek week;

  const AssessmentTab({super.key, required this.week});

  @override
  State<AssessmentTab> createState() => _AssessmentTabState();
}

class _AssessmentTabState extends State<AssessmentTab> {
  bool _sleepCommitted = false;
  bool _caloriesCommitted = false;
  String _progress = 'no_progress';
  String _fatigue = 'low';
  bool _fluidsCommitted = false;
  bool _stepsCommitted = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final assessment = context.read<FitnessProvider>().assessment;
      if (assessment != null) {
        _sleepCommitted = assessment.sleepCommitted;
        _caloriesCommitted = assessment.caloriesCommitted;
        _progress = assessment.progress;
        _fatigue = assessment.fatigue;
        _fluidsCommitted = assessment.fluidsCommitted;
        _stepsCommitted = assessment.stepsCommitted;
      }
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l.weekEndAssessment,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),

        _buildToggleQuestion(l.sleepCommitment, _sleepCommitted, (v) {
          setState(() => _sleepCommitted = v);
        }),

        _buildToggleQuestion(l.calorieNeeds, _caloriesCommitted, (v) {
          setState(() => _caloriesCommitted = v);
        }),

        _buildProgressQuestion(),
        _buildFatigueQuestion(),

        _buildToggleQuestion(l.fluids, _fluidsCommitted, (v) {
          setState(() => _fluidsCommitted = v);
        }),

        _buildToggleQuestion(l.stepsLabel, _stepsCommitted, (v) {
          setState(() => _stepsCommitted = v);
        }),

        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saveAssessment,
          icon: const Icon(Icons.save_rounded),
          label: Text(l.saveAssessment),
        ),
      ],
    );
  }

  Widget _buildToggleQuestion(String label, bool value, ValueChanged<bool> onChanged) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: SwitchListTile(
        title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(
          value ? l.committed : l.notCommitted,
          style: TextStyle(
            fontSize: 12,
            color: value ? AppColors.accent : AppColors.textTertiary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildProgressQuestion() {
    final l = AppLocalizations.of(context);
    final options = {
      'no_progress': l.noProgress,
      'slight': l.slightProgress,
      'normal': l.normalProgress,
      'historic': l.historicProgress,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.progress, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.entries.map((e) {
              final isSelected = _progress == e.key;
              return GestureDetector(
                onTap: () => setState(() => _progress = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentDim : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFatigueQuestion() {
    final l = AppLocalizations.of(context);
    final options = {
      'low': l.low,
      'medium': l.medium,
      'high': l.high,
    };

    final colors = {
      'low': AppColors.success,
      'medium': AppColors.warning,
      'high': AppColors.error,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.fatigue, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: options.entries.map((e) {
              final isSelected = _fatigue == e.key;
              final color = colors[e.key]!;
              return GestureDetector(
                onTap: () => setState(() => _fatigue = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? color : AppColors.border,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? color : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _saveAssessment() {
    final l = AppLocalizations.of(context);
    context.read<FitnessProvider>().saveAssessment(
      weekId: widget.week.id,
      sleepCommitted: _sleepCommitted,
      caloriesCommitted: _caloriesCommitted,
      progress: _progress,
      fatigue: _fatigue,
      fluidsCommitted: _fluidsCommitted,
      stepsCommitted: _stepsCommitted,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.assessmentSaved), duration: const Duration(seconds: 2)),
    );
  }
}
