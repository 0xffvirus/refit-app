import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/fitness_week.dart';
import '../../providers/fitness_provider.dart';
import '../../services/tutorial_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/tutorial/tutorial_steps.dart';
import 'week_detail_screen.dart';

class WeekListScreen extends StatefulWidget {
  const WeekListScreen({super.key});

  @override
  State<WeekListScreen> createState() => _WeekListScreenState();
}

class _WeekListScreenState extends State<WeekListScreen> {
  final _fabKey = GlobalKey();
  final _firstWeekKey = GlobalKey();

  bool _firstVisitShown = false;
  bool _firstVisitComplete = false;
  bool _deferredShown = false;
  int _lastWeekCount = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<FitnessProvider>().initialize();
    });
    TutorialService.instance.pendingTab.addListener(_onPendingTab);
  }

  @override
  void dispose() {
    TutorialService.instance.pendingTab.removeListener(_onPendingTab);
    super.dispose();
  }

  void _onPendingTab() {
    if (TutorialService.instance.pendingTab.value != TabId.fitness) return;
    if (!mounted || _firstVisitShown) return;
    _firstVisitShown = true;
    TutorialService.instance.clearPending(TabId.fitness);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showFirstVisitTour();
    });
  }

  void _showFirstVisitTour() {
    showCoachMarks(
      context: context,
      targets: fitnessFirstVisitTargets(
        context: context,
        fabKey: _fabKey,
      ),
      onSeen: () async {
        _firstVisitComplete = true;
        await TutorialService.instance.markSeen(TabId.fitness);
        _maybeStartDeferred();
      },
    );
  }

  void _maybeStartDeferred() {
    if (!_firstVisitComplete || _deferredShown) return;
    final weeks = context.read<FitnessProvider>().weeks;
    if (weeks.isNotEmpty) {
      _showDeferredTour();
    }
  }

  void _showDeferredTour() {
    if (_deferredShown) return;
    _deferredShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      showCoachMarks(
        context: context,
        targets: fitnessDeferredTargets(
          context: context,
          weekCardKey: _firstWeekKey,
        ),
        onSeen: () {
          // Bonus tip — flag already set.
        },
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final count = context.watch<FitnessProvider>().weeks.length;
    if (count > 0 && _lastWeekCount == 0 && _firstVisitComplete && !_deferredShown) {
      _showDeferredTour();
    }
    _lastWeekCount = count;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final provider = context.watch<FitnessProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l.fitnessTracking)),
      body: provider.weeks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fitness_center, size: 56, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text(
                    l.noWeeks,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            )
          : _buildGroupedList(context, provider),
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        onPressed: () => _showCreateOptions(context, provider),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildGroupedList(BuildContext context, FitnessProvider provider) {
    final l = AppLocalizations.of(context);
    // Group weeks by year-month
    final grouped = <String, List<FitnessWeek>>{};
    for (final week in provider.weeks) {
      final key = '${week.startDate.year}-${week.startDate.month}';
      grouped.putIfAbsent(key, () => []).add(week);
    }

    // Sort keys: most recent first
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (ctx, i) {
        final key = sortedKeys[i];
        final weeks = grouped[key]!;
        final year = int.parse(key.split('-')[0]);
        final month = int.parse(key.split('-')[1]);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (i > 0) const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 10, right: 4),
              child: Text(
                '${l.months[month - 1]} $year',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ...weeks.asMap().entries.map((entry) {
              final isFirstOverall = i == 0 && entry.key == 0;
              return _buildWeekCard(
                context,
                entry.value,
                keyOverride: isFirstOverall ? _firstWeekKey : null,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildWeekCard(BuildContext context, FitnessWeek week, {Key? keyOverride}) {
    final l = AppLocalizations.of(context);
    final dateFormat = DateFormat('d/M');
    final startStr = dateFormat.format(week.startDate);
    final endStr = dateFormat.format(week.endDate);

    final now = DateTime.now();
    final isCurrentWeek = now.isAfter(week.startDate.subtract(const Duration(days: 1))) &&
        now.isBefore(week.endDate.add(const Duration(days: 1)));

    return GestureDetector(
      key: keyOverride,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WeekDetailScreen(week: week)),
      ),
      onLongPress: () => _confirmDeleteWeek(context, week),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentWeek ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border,
            width: isCurrentWeek ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCurrentWeek ? AppColors.accent : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_view_week_rounded,
                color: isCurrentWeek ? AppColors.background : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.weekLabel(startStr, endStr),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCurrentWeek
                        ? l.currentWeekYear(week.startDate.year)
                        : '${week.startDate.year}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showCreateOptions(BuildContext context, FitnessProvider provider) {
    final l = AppLocalizations.of(context);
    final currentWeekSunday = _getSunday(DateTime.now());
    final nextWeekSunday = currentWeekSunday.add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.today, color: AppColors.accent),
                title: Text(l.currentWeek),
                subtitle: Text(
                  '${DateFormat('d/M').format(currentWeekSunday)} - ${DateFormat('d/M').format(currentWeekSunday.add(const Duration(days: 6)))}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _createAndOpen(context, provider, currentWeekSunday);
                },
              ),
              ListTile(
                leading: const Icon(Icons.next_week, color: AppColors.accent),
                title: Text(l.nextWeek),
                subtitle: Text(
                  '${DateFormat('d/M').format(nextWeekSunday)} - ${DateFormat('d/M').format(nextWeekSunday.add(const Duration(days: 6)))}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _createAndOpen(context, provider, nextWeekSunday);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: AppColors.accent),
                title: Text(l.pickDate),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCustomWeek(context, provider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAndOpen(BuildContext context, FitnessProvider provider, DateTime sunday) async {
    final week = await provider.createWeek(sunday);
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WeekDetailScreen(week: week)));
    }
  }

  Future<void> _pickCustomWeek(BuildContext context, FitnessProvider provider) async {
    final l = AppLocalizations.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: l.pickDayHint,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: AppColors.surfaceLight,
              todayBorder: const BorderSide(color: AppColors.accent),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      final sunday = _getSunday(picked);
      await _createAndOpen(context, provider, sunday);
    }
  }

  DateTime _getSunday(DateTime date) {
    final daysToSubtract = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }

  void _confirmDeleteWeek(BuildContext context, FitnessWeek week) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteWeek),
        content: Text(l.deleteWeekConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<FitnessProvider>().deleteWeek(week.id);
              Navigator.pop(ctx);
            },
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }
}
