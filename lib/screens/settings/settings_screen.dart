import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/habit_provider.dart';
import '../../providers/fitness_provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/database_service.dart';
import '../../services/health_service.dart';
import '../../services/tutorial_service.dart';
import '../../widgets/tutorial/tutorial_steps.dart';
import '../../utils/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'one_rep_max_screen.dart';
import 'body_fat_screen.dart';
import 'ideal_weight_screen.dart';

const _waterColor = Color(0xFF4FC3F7);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _calculatorsKey = GlobalKey();
  final _appleHealthKey = GlobalKey();
  final _backupKey = GlobalKey();
  final _scrollController = ScrollController();
  bool _tutorialShown = false;

  @override
  void initState() {
    super.initState();
    TutorialService.instance.pendingTab.addListener(_onPendingTab);
  }

  @override
  void dispose() {
    TutorialService.instance.pendingTab.removeListener(_onPendingTab);
    _scrollController.dispose();
    super.dispose();
  }

  void _onPendingTab() {
    if (TutorialService.instance.pendingTab.value != TabId.tools) return;
    if (!mounted || _tutorialShown) return;
    _tutorialShown = true;
    TutorialService.instance.clearPending(TabId.tools);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showTour();
    });
  }

  void _showTour() async {
    // Reset the ListView to the top so the first target (calculators) is
    // fully in view before the overlay renders. Guards against the case
    // where the user scrolled the list before the tutorial fired.
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    if (!mounted) return;
    showCoachMarks(
      context: context,
      targets: toolsTargets(
        context: context,
        calculatorsKey: _calculatorsKey,
        appleHealthKey: Platform.isIOS ? _appleHealthKey : null,
        backupKey: _backupKey,
      ),
      onSeen: () async {
        await TutorialService.instance.markSeen(TabId.tools);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.tools)),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            key: _calculatorsKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.calculators,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _waterColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.water_drop, size: 20, color: _waterColor),
                  ),
                  title: Text(l.waterIntakeCalc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(l.waterIntakeDesc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_left, color: AppColors.textTertiary),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WaterIntakeCalculatorScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_fire_department, size: 20, color: AppColors.warning),
                  ),
                  title: Text(l.macroCalc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(l.macroCalcDesc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_left, color: AppColors.textTertiary),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MacroCalculatorScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.monitor_weight_outlined, size: 20, color: AppColors.success),
                  ),
                  title: Text(l.bmiCalc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(l.bmiCalcDesc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_left, color: AppColors.textTertiary),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BmiCalculatorScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fitness_center, size: 20, color: AppColors.error),
                  ),
                  title: Text(l.oneRmCalc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(l.oneRmCalcDesc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_left, color: AppColors.textTertiary),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OneRepMaxScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.mood.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.percent, size: 20, color: AppColors.mood),
                  ),
                  title: Text(l.bodyFatCalc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(l.bodyFatCalcDesc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_left, color: AppColors.textTertiary),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BodyFatScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.accessibility_new, size: 20, color: AppColors.accent),
                  ),
                  title: Text(l.idealWeightCalc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(l.idealWeightCalcDesc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_left, color: AppColors.textTertiary),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IdealWeightScreen()),
                  ),
                ),
              ),
            ],
          ),
          if (Platform.isIOS) ...[
            const SizedBox(height: 24),
            Column(
              key: _appleHealthKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.appleHealth,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                _HealthSyncTile(),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text(
            l.language,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Consumer<LocaleProvider>(
              builder: (context, localeProvider, _) {
                return Column(
                  children: [
                    _buildLanguageOption(
                      context,
                      label: l.arabic,
                      subtitle: 'العربية',
                      isSelected: localeProvider.isArabic,
                      onTap: () => localeProvider.setLocale(const Locale('ar')),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildLanguageOption(
                      context,
                      label: l.english,
                      subtitle: 'English',
                      isSelected: !localeProvider.isArabic,
                      onTap: () => localeProvider.setLocale(const Locale('en')),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Column(
            key: _backupKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.backup,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.upload_file_rounded, color: AppColors.info, size: 20),
                      ),
                      title: Text(l.exportBackup, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(l.exportBackupDesc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      onTap: () => _exportBackup(context),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.download_rounded, color: AppColors.success, size: 20),
                      ),
                      title: Text(l.importBackup, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(l.importBackupDesc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      onTap: () => _importBackup(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.backupNote,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l.tools,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.replay_rounded, size: 20, color: AppColors.accent),
              ),
              title: Text(
                l.tutorialReplayTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                l.tutorialReplaySubtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_left, color: AppColors.textTertiary),
              onTap: () async {
                await TutorialService.instance.resetAllFlags();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.tutorialReplayConfirmSnack)),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      _showLoading(context, l.exporting);
      final db = DatabaseService();
      final file = await db.exportToFile();

      if (context.mounted) Navigator.pop(context);

      await Share.shareXFiles([XFile(file.path)], subject: 'Refit Backup');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showError(context, l.exportFailed(e.toString()));
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.importConfirmTitle),
        content: Text(
          l.importConfirmBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.confirmImport),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      if (!context.mounted) return;
      _showLoading(context, l.importing);

      final file = File(result.files.single.path!);
      final db = DatabaseService();
      await db.importFromFile(file);

      if (context.mounted) {
        Navigator.pop(context);

        context.read<HabitProvider>().initialize();
        context.read<FitnessProvider>().initialize();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.importSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showError(context, l.importFailed(e.toString()));
      }
    }
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.language_rounded,
          size: 20,
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 22)
          : null,
      onTap: onTap,
    );
  }

  void _showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class WaterIntakeCalculatorScreen extends StatefulWidget {
  const WaterIntakeCalculatorScreen({super.key});

  @override
  State<WaterIntakeCalculatorScreen> createState() => _WaterIntakeCalculatorScreenState();
}

class _WaterIntakeCalculatorScreenState extends State<WaterIntakeCalculatorScreen> {
  final _weightController = TextEditingController();
  double _multiplier = 35;
  int? _resultMl;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) return;
    setState(() {
      _resultMl = (weight * _multiplier).round();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.waterIntakeCalc)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
                  l.enterWeightForWater,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: l.enterWeight,
              suffixText: l.kg,
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 12),
          Text(
            l.consumptionRate,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _multiplierChip(30, l.lowRate, l),
              const SizedBox(width: 8),
              _multiplierChip(33, l.mediumRate, l),
              const SizedBox(width: 8),
              _multiplierChip(35, l.highRate, l),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.highRateNote,
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
          if (_resultMl != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _waterColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _waterColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    l.dailyNeeds,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.mlAmount(_resultMl!),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _waterColor,
                    ),
                  ),
                  Text(
                    '(${(_resultMl! / 1000).toStringAsFixed(1)} ${l.liter})',
                    style: TextStyle(
                      fontSize: 14,
                      color: _waterColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.read<WaterProvider>().setGoal(_resultMl!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.waterGoalUpdated)),
                        );
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(l.setAsDailyGoal),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.waterFormula,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _multiplierChip(double value, String label, AppLocalizations l) {
    final isSelected = _multiplier == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _multiplier = value);
          _calculate();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _waterColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _waterColor : AppColors.border,
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                l.mlPerKg(value.toInt()),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _waterColor : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? _waterColor.withValues(alpha: 0.7) : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Macro Calculator ──

enum _Gender { male, female }

enum _FormulaType { mifflinStJeor, katchMcArdle }

enum _Goal { cut, maintain, lean, aggressive }

Map<_Goal, String> _getGoalLabels(AppLocalizations l) => {
  _Goal.aggressive: l.goalLabels['aggressive']!,
  _Goal.cut: l.goalLabels['cut']!,
  _Goal.maintain: l.goalLabels['maintain']!,
  _Goal.lean: l.goalLabels['lean']!,
};

const _goalAdjustments = {
  _Goal.aggressive: -625,
  _Goal.cut: -400,
  _Goal.maintain: 0,
  _Goal.lean: 300,
};

List<String> _getActivityLabels(AppLocalizations l) => l.activityLabels;

const _activityFactors = [1.2, 1.375, 1.55, 1.725, 1.9];

List<String> _getProteinLabels(AppLocalizations l) => l.proteinLabels;

const _proteinRanges = [
  (min: 0.8, max: 1.0),
  (min: 1.4, max: 1.8),
  (min: 1.6, max: 2.2),
  (min: 2.0, max: 2.4),
];

class MacroCalculatorScreen extends StatefulWidget {
  const MacroCalculatorScreen({super.key});

  @override
  State<MacroCalculatorScreen> createState() => _MacroCalculatorScreenState();
}

class _MacroCalculatorScreenState extends State<MacroCalculatorScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _lbmController = TextEditingController();

  _Gender _gender = _Gender.male;
  _FormulaType _formula = _FormulaType.mifflinStJeor;
  int _activityIndex = 2;
  _Goal _goal = _Goal.maintain;
  int _proteinIndex = 1;
  double _fatMultiplier = 1.0;

  // Results
  double? _bmr;
  double? _tdee;
  int? _targetCalories;
  int? _proteinG;
  int? _fatG;
  int? _carbsG;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _lbmController.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      setState(() { _bmr = null; });
      return;
    }

    double bmr;

    if (_formula == _FormulaType.katchMcArdle) {
      final lbm = double.tryParse(_lbmController.text.trim());
      if (lbm == null || lbm <= 0) {
        setState(() { _bmr = null; });
        return;
      }
      bmr = 370 + (21.6 * lbm);
    } else {
      final height = double.tryParse(_heightController.text.trim());
      final age = int.tryParse(_ageController.text.trim());
      if (height == null || height <= 0 || age == null || age <= 0) {
        setState(() { _bmr = null; });
        return;
      }
      bmr = (10 * weight) + (6.25 * height) - (5 * age);
      bmr += _gender == _Gender.male ? 5 : -161;
    }

    final tdee = bmr * _activityFactors[_activityIndex];
    final targetCal = tdee + _goalAdjustments[_goal]!;

    final proteinRange = _proteinRanges[_proteinIndex];
    final proteinPerKg = (proteinRange.min + proteinRange.max) / 2;
    final proteinG = (weight * proteinPerKg).round();
    final fatG = (weight * _fatMultiplier).round();
    final proteinCal = proteinG * 4;
    final fatCal = fatG * 9;
    final carbsG = ((targetCal - proteinCal - fatCal) / 4).round().clamp(0, 9999);

    setState(() {
      _bmr = bmr;
      _tdee = tdee;
      _targetCalories = targetCal.round();
      _proteinG = proteinG;
      _fatG = fatG;
      _carbsG = carbsG;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.macroCalc)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInputSection(l),
          const SizedBox(height: 12),
          _buildFormulaSection(l),
          const SizedBox(height: 12),
          _buildActivitySection(l),
          const SizedBox(height: 12),
          _buildGoalSection(l),
          const SizedBox(height: 12),
          _buildMacroSettingsSection(l),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () { FocusScope.of(context).unfocus(); _calculate(); },
              child: Text(l.calculate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          if (_bmr != null) ...[
            const SizedBox(height: 20),
            _buildResults(l),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInputSection(AppLocalizations l) {
    return _sectionCard(
      title: l.basicData,
      child: Column(
        children: [
          Row(
            children: [
              _choiceChip(l.male, _gender == _Gender.male, () => setState(() { _gender = _Gender.male; })),
              const SizedBox(width: 8),
              _choiceChip(l.female, _gender == _Gender.female, () => setState(() { _gender = _Gender.female; })),
            ],
          ),
          const SizedBox(height: 12),
          _inputField(_weightController, l.weightField, l.kg),
          if (_formula == _FormulaType.mifflinStJeor) ...[
            const SizedBox(height: 10),
            _inputField(_heightController, l.heightField, l.cm),
            const SizedBox(height: 10),
            _inputField(_ageController, l.ageField, l.yearUnit, decimal: false),
          ],
          if (_formula == _FormulaType.katchMcArdle) ...[
            const SizedBox(height: 10),
            _inputField(_lbmController, l.leanBodyMass, l.kg),
          ],
        ],
      ),
    );
  }

  Widget _buildFormulaSection(AppLocalizations l) {
    return _sectionCard(
      title: l.bmrFormula,
      child: Column(
        children: [
          Row(
            children: [
              _choiceChip('Mifflin-St Jeor', _formula == _FormulaType.mifflinStJeor, () => setState(() { _formula = _FormulaType.mifflinStJeor; })),
              const SizedBox(width: 8),
              _choiceChip('Katch-McArdle', _formula == _FormulaType.katchMcArdle, () => setState(() { _formula = _FormulaType.katchMcArdle; })),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formula == _FormulaType.mifflinStJeor
                ? l.mifflinAccuracy
                : l.katchAccuracy,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(AppLocalizations l) {
    final activityLabels = _getActivityLabels(l);
    return _sectionCard(
      title: l.activityLevel,
      child: Column(
        children: List.generate(activityLabels.length, (i) {
          final isSelected = _activityIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _activityIndex = i),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      activityLabels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppColors.accent : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '×${_activityFactors[i]}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? AppColors.accent : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGoalSection(AppLocalizations l) {
    final goalLabels = _getGoalLabels(l);
    return _sectionCard(
      title: l.goal,
      child: Row(
        children: _Goal.values.map((g) {
          final isSelected = _goal == g;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _goal = g),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      goalLabels[g]!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_goalAdjustments[g]! >= 0 ? '+' : ''}${_goalAdjustments[g]}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? AppColors.accent.withValues(alpha: 0.7) : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMacroSettingsSection(AppLocalizations l) {
    final proteinLabels = _getProteinLabels(l);
    final fatLabelsList = l.fatLabels;
    return _sectionCard(
      title: l.macroDistribution,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.proteinPerKg, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(proteinLabels.length, (i) {
              final isSelected = _proteinIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _proteinIndex = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(
                    proteinLabels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(l.fatPerKg, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              (value: 0.7, label: fatLabelsList[0]),
              (value: 0.85, label: fatLabelsList[1]),
              (value: 1.0, label: fatLabelsList[2]),
              (value: 1.2, label: fatLabelsList[3]),
            ].map((opt) {
              final isSelected = _fatMultiplier == opt.value;
              return GestureDetector(
                onTap: () => setState(() => _fatMultiplier = opt.value),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            l.carbsNote,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _resultMiniCard('BMR', '${_bmr!.round()}', l.calorieSuffix),
              const SizedBox(width: 10),
              _resultMiniCard('TDEE', '${_tdee!.round()}', l.calorieSuffix),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(l.targetCalories, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  '$_targetCalories',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
                Text(l.caloriesPerDay, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _macroCard(l.protein, '$_proteinG ${l.grams}', '${_proteinG! * 4} ${l.calorieSuffix}', AppColors.info),
              const SizedBox(width: 8),
              _macroCard(l.fats, '$_fatG ${l.grams}', '${_fatG! * 9} ${l.calorieSuffix}', AppColors.warning),
              const SizedBox(width: 8),
              _macroCard(l.carbs, '$_carbsG ${l.grams}', '${_carbsG! * 4} ${l.calorieSuffix}', AppColors.success),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                context.read<FitnessProvider>().updateMacroTargets(
                  calories: _targetCalories!.toDouble(),
                  protein: _proteinG!.toDouble(),
                  carbs: _carbsG!.toDouble(),
                  fat: _fatG!.toDouble(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.macroTargetsUpdated)),
                );
              },
              icon: const Icon(Icons.check, size: 18),
              label: Text(l.setAsDailyTargets),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultMiniCard(String label, String value, String unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(unit, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _macroCard(String label, String amount, String calories, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 6),
            Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(calories, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint, String suffix, {bool decimal = true}) {
    return TextField(
      controller: controller,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── BMI Calculator ──

class BmiCalculatorScreen extends StatefulWidget {
  const BmiCalculatorScreen({super.key});

  @override
  State<BmiCalculatorScreen> createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends State<BmiCalculatorScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  double? _bmi;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text.trim());
    final heightCm = double.tryParse(_heightController.text.trim());
    if (weight == null || weight <= 0 || heightCm == null || heightCm <= 0) {
      setState(() => _bmi = null);
      return;
    }
    final heightM = heightCm / 100;
    setState(() => _bmi = weight / (heightM * heightM));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.bmiTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.dataSection, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: l.weightField,
                    suffixText: l.kg,
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (_) => _calculate(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: l.heightField,
                    suffixText: l.cm,
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (_) => _calculate(),
                ),
              ],
            ),
          ),
          if (_bmi != null) ...[
            const SizedBox(height: 20),
            _buildResult(l),
            const SizedBox(height: 16),
            _buildScale(),
            const SizedBox(height: 16),
            _buildCategories(l),
          ],
          const SizedBox(height: 16),
          _buildSources(l),
          const SizedBox(height: 16),
          _buildBmiDisclaimer(l),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResult(AppLocalizations l) {
    final category = _bmiCategory(_bmi!, l);
    final color = _bmiColor(_bmi!);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(l.bodyMassIndex, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _bmi!),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return Text(
                value.toStringAsFixed(1),
                style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: color),
              );
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              category,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScale() {
    final position = ((_bmi! - 15) / 25).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Scale bar
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            _scaleSegment(AppColors.info, 3.5 / 25),
                            _scaleSegment(AppColors.success, 6.5 / 25),
                            _scaleSegment(AppColors.warning, 5.0 / 25),
                            _scaleSegment(AppColors.error, 10.0 / 25),
                          ],
                        ),
                      ),
                    ),
                    // Indicator
                    Positioned(
                      top: 0,
                      left: (width * position) - 10,
                      child: Column(
                        children: [
                          Icon(Icons.arrow_drop_down, size: 28, color: _bmiColor(_bmi!)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('15', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              Text('18.5', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              Text('25', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              Text('30', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              Text('40', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scaleSegment(Color color, double flex) {
    return Expanded(
      flex: (flex * 100).round(),
      child: Container(height: 8, color: color),
    );
  }

  Widget _buildCategories(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.categories, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _categoryRow(l.underweight, '< 18.5', AppColors.info, _bmi! < 18.5),
          _categoryRow(l.normalWeight, '18.5 - 24.9', AppColors.success, _bmi! >= 18.5 && _bmi! < 25),
          _categoryRow(l.overweight, '25 - 29.9', AppColors.warning, _bmi! >= 25 && _bmi! < 30),
          _categoryRow(l.obese, '≥ 30', AppColors.error, _bmi! >= 30),
        ],
      ),
    );
  }

  Widget _categoryRow(String label, String range, Color color, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? color : AppColors.border,
          width: isActive ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? color : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            range,
            style: TextStyle(fontSize: 12, color: isActive ? color : AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildSources(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.sources, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Text(l.bmiSource, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('https://www.who.int/news-room/fact-sheets/detail/obesity-and-overweight')),
            child: const Text(
              'who.int — BMI Classification',
              style: TextStyle(fontSize: 12, color: AppColors.info, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBmiDisclaimer(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.bmiDisclaimer, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(l.medicalDisclaimer, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _bmiCategory(double bmi, AppLocalizations l) {
    if (bmi < 18.5) return l.underweight;
    if (bmi < 25) return l.normalWeight;
    if (bmi < 30) return l.overweight;
    return l.obese;
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return AppColors.info;
    if (bmi < 25) return AppColors.success;
    if (bmi < 30) return AppColors.warning;
    return AppColors.error;
  }
}

class _HealthSyncTile extends StatefulWidget {
  @override
  State<_HealthSyncTile> createState() => _HealthSyncTileState();
}

class _HealthSyncTileState extends State<_HealthSyncTile> {
  final _health = HealthService();
  bool _enabled = false;
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final enabled = await _health.isEnabled;
    if (mounted) setState(() { _enabled = enabled; _loading = false; });
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      final granted = await _health.requestPermissions();
      if (!granted) {
        if (mounted) {
          final l = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.healthPermissionDenied)),
          );
        }
        return;
      }
    }

    await _health.setEnabled(value);
    setState(() => _enabled = value);

    if (value && mounted) {
      setState(() => _syncing = true);
      await context.read<FitnessProvider>().syncHealthData();
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.favorite_rounded, size: 20, color: AppColors.error),
        ),
        title: Text(l.syncAppleHealth, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(
          _syncing ? l.syncing : l.healthSyncData,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Switch(value: _enabled, onChanged: _toggle),
      ),
    );
  }
}
