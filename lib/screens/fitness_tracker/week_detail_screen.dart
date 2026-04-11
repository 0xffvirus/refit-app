import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/fitness_week.dart';
import '../../providers/fitness_provider.dart';
import '../../utils/app_theme.dart';
import 'nutrition_tab.dart';
import 'weight_tab.dart';
import 'assessment_tab.dart';
import 'measurements_tab.dart';
import 'steps_tab.dart';

class WeekDetailScreen extends StatefulWidget {
  final FitnessWeek week;

  const WeekDetailScreen({super.key, required this.week});

  @override
  State<WeekDetailScreen> createState() => _WeekDetailScreenState();
}

class _WeekDetailScreenState extends State<WeekDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    Future.microtask(() {
      context.read<FitnessProvider>().loadWeekDetails(widget.week.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dateFormat = DateFormat('d/M');
    final startStr = dateFormat.format(widget.week.startDate);
    final endStr = dateFormat.format(widget.week.endDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.weekLabel(startStr, endStr)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorSize: TabBarIndicatorSize.label,
          indicator: UnderlineTabIndicator(
            borderSide: const BorderSide(color: AppColors.accent, width: 2.5),
            borderRadius: BorderRadius.circular(2),
          ),
          tabs: [
            Tab(text: l.nutrition, icon: const Icon(Icons.restaurant_rounded, size: 20)),
            Tab(text: l.weight, icon: const Icon(Icons.monitor_weight_rounded, size: 20)),
            Tab(text: l.steps, icon: const Icon(Icons.directions_walk_rounded, size: 20)),
            Tab(text: l.assessment, icon: const Icon(Icons.checklist_rounded, size: 20)),
            Tab(text: l.measurements, icon: const Icon(Icons.straighten_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NutritionTab(week: widget.week),
          WeightTab(week: widget.week),
          StepsTab(week: widget.week),
          AssessmentTab(week: widget.week),
          MeasurementsTab(week: widget.week),
        ],
      ),
    );
  }
}
