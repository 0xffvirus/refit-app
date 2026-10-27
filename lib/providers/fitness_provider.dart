import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/fitness_week.dart';
import '../models/nutrition_entry.dart';
import '../models/weight_entry.dart';
import '../models/weekly_assessment.dart';
import '../models/body_measurement.dart';
import '../models/step_entry.dart';
import '../services/database_service.dart';
import '../services/health_service.dart';
import '../utils/request_sequencer.dart';

class FitnessProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final HealthService _health = HealthService();
  final _uuid = const Uuid();

  List<FitnessWeek> _weeks = [];
  List<FitnessWeek> get weeks => _weeks;

  // Macro targets (persistent across weeks)
  Map<String, double> _macroTargets = {
    'calories': 0,
    'protein': 0,
    'carbs': 0,
    'fat': 0,
  };
  Map<String, double> get macroTargets => _macroTargets;

  // Step goal (persistent across weeks)
  int _stepGoal = 10000;
  int get stepGoal => _stepGoal;

  // Current week detail data
  List<NutritionEntry> _nutritionEntries = [];
  List<WeightEntry> _weightEntries = [];
  List<StepEntry> _stepEntries = [];
  WeeklyAssessment? _assessment;
  BodyMeasurement? _measurement;

  // The week whose details are loaded. Async results for any other week are
  // dropped so they can't overwrite what the user is looking at.
  String? _activeWeekId;
  final _weekLoads = RequestSequencer();
  Future<void>? _healthSync;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  List<NutritionEntry> get nutritionEntries => _nutritionEntries;
  List<WeightEntry> get weightEntries => _weightEntries;
  List<StepEntry> get stepEntries => _stepEntries;
  WeeklyAssessment? get assessment => _assessment;
  BodyMeasurement? get measurement => _measurement;

  double get weeklyAverageWeight {
    if (_weightEntries.isEmpty) return 0;
    final sum = _weightEntries.fold<double>(0, (acc, e) => acc + e.weight);
    return sum / _weightEntries.length;
  }

  Map<String, double> get weeklyAverageNutrition {
    if (_nutritionEntries.isEmpty) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }
    final count = _nutritionEntries.length;
    return {
      'calories':
          _nutritionEntries.fold<double>(0, (a, e) => a + e.calories) / count,
      'protein':
          _nutritionEntries.fold<double>(0, (a, e) => a + e.protein) / count,
      'carbs': _nutritionEntries.fold<double>(0, (a, e) => a + e.carbs) / count,
      'fat': _nutritionEntries.fold<double>(0, (a, e) => a + e.fat) / count,
    };
  }

  int get weeklyAverageSteps {
    if (_stepEntries.isEmpty) return 0;
    final sum = _stepEntries.fold<int>(0, (acc, e) => acc + e.steps);
    return sum ~/ _stepEntries.length;
  }

  int get weeklyTotalSteps {
    return _stepEntries.fold<int>(0, (acc, e) => acc + e.steps);
  }

  StepEntry? getStepsForDate(DateTime date) {
    final dateStr = _dateOnly(date);
    final matches = _stepEntries.where((e) => _dateOnly(e.date) == dateStr);
    return matches.isEmpty ? null : matches.first;
  }

  /// Syncs health data for the current week. Concurrent calls (app start and
  /// resume firing together) share a single in-flight sync.
  Future<void> syncHealthData() {
    return _healthSync ??= _syncHealthData().whenComplete(() {
      _healthSync = null;
    });
  }

  Future<void> _syncHealthData() async {
    await _health.syncCurrentWeek(
      existingWeeks: _weeks,
      createWeek: (startDate) async {
        final week = await _db.createFitnessWeek(startDate);
        _weeks = await _db.fetchAllFitnessWeeks();
        notifyListeners();
        return week;
      },
      loadWeekDetails: (weekId) async {
        // Only refresh if the synced week is the one on screen.
        if (weekId == _activeWeekId) await loadWeekDetails(weekId);
      },
    );
    // Refresh weeks list in case a new one was created
    _weeks = await _db.fetchAllFitnessWeeks();
    notifyListeners();
  }

  Future<void> initialize() async {
    _weeks = await _db.fetchAllFitnessWeeks();
    _macroTargets = await _db.fetchMacroTargets();
    _stepGoal = await _db.fetchStepGoal();
    notifyListeners();
  }

  Future<void> updateMacroTargets({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    await _db.updateMacroTargets(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
    _macroTargets = {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
    notifyListeners();
  }

  Future<void> updateStepGoal(int goal) async {
    await _db.updateStepGoal(goal);
    _stepGoal = goal;
    notifyListeners();
  }

  Future<void> loadWeekDetails(String weekId) async {
    final token = _weekLoads.next();
    if (weekId != _activeWeekId) {
      // Don't show the previous week's data while the new one loads.
      _activeWeekId = weekId;
      _clearWeekDetails();
      notifyListeners();
    }
    final nutrition = await _db.fetchNutritionForWeek(weekId);
    final weights = await _db.fetchWeightsForWeek(weekId);
    final steps = await _db.fetchStepsForWeek(weekId);
    final assessment = await _db.fetchAssessmentForWeek(weekId);
    final measurement = await _db.fetchMeasurementForWeek(weekId);
    if (!_weekLoads.isCurrent(token)) return;
    _nutritionEntries = nutrition;
    _weightEntries = weights;
    _stepEntries = steps;
    _assessment = assessment;
    _measurement = measurement;
    notifyListeners();
  }

  void _clearWeekDetails() {
    _nutritionEntries = [];
    _weightEntries = [];
    _stepEntries = [];
    _assessment = null;
    _measurement = null;
  }

  Future<FitnessWeek> createWeek(DateTime startDate) async {
    final week = await _db.createFitnessWeek(startDate);
    _weeks = await _db.fetchAllFitnessWeeks();
    notifyListeners();
    return week;
  }

  Future<void> deleteWeek(String weekId) async {
    await _db.deleteFitnessWeek(weekId);
    if (weekId == _activeWeekId) {
      _activeWeekId = null;
      _weekLoads.invalidate();
      _clearWeekDetails();
    }
    _weeks = await _db.fetchAllFitnessWeeks();
    notifyListeners();
  }

  Future<void> saveNutritionEntry({
    required String weekId,
    required DateTime date,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    final entry = NutritionEntry(
      id: _uuid.v4(),
      weekId: weekId,
      date: date,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
    await _db.upsertNutritionEntry(entry);
    final entries = await _db.fetchNutritionForWeek(weekId);
    if (weekId != _activeWeekId) return;
    _nutritionEntries = entries;
    notifyListeners();
  }

  Future<void> saveWeightEntry({
    required String weekId,
    required DateTime date,
    required double weight,
  }) async {
    final entry = WeightEntry(
      id: _uuid.v4(),
      weekId: weekId,
      date: date,
      weight: weight,
    );
    await _db.upsertWeightEntry(entry);
    final entries = await _db.fetchWeightsForWeek(weekId);
    if (weekId != _activeWeekId) return;
    _weightEntries = entries;
    notifyListeners();
  }

  Future<void> saveAssessment({
    required String weekId,
    required bool sleepCommitted,
    required bool caloriesCommitted,
    required String progress,
    required String fatigue,
    required bool fluidsCommitted,
    required bool stepsCommitted,
  }) async {
    final existing = await _db.fetchAssessmentForWeek(weekId);
    final assessment = WeeklyAssessment(
      id: existing?.id ?? _uuid.v4(),
      weekId: weekId,
      sleepCommitted: sleepCommitted,
      caloriesCommitted: caloriesCommitted,
      progress: progress,
      fatigue: fatigue,
      fluidsCommitted: fluidsCommitted,
      stepsCommitted: stepsCommitted,
    );
    await _db.upsertWeeklyAssessment(assessment);
    if (weekId != _activeWeekId) return;
    _assessment = assessment;
    notifyListeners();
  }

  Future<void> saveMeasurement({
    required String weekId,
    required double chest,
    required double calves,
    required double waist,
    required double glutes,
    required double arm,
    required double thigh,
    String? frontPhotoPath,
    String? backPhotoPath,
  }) async {
    final existing = await _db.fetchMeasurementForWeek(weekId);
    final m = BodyMeasurement(
      id: existing?.id ?? _uuid.v4(),
      weekId: weekId,
      chest: chest,
      calves: calves,
      waist: waist,
      glutes: glutes,
      arm: arm,
      thigh: thigh,
      frontPhotoPath: frontPhotoPath ?? existing?.frontPhotoPath,
      backPhotoPath: backPhotoPath ?? existing?.backPhotoPath,
    );
    await _db.upsertBodyMeasurement(m);
    if (weekId != _activeWeekId) return;
    _measurement = m;
    notifyListeners();
  }

  Future<List<BodyMeasurement>> fetchAllMeasurementsForComparison() async {
    return await _db.fetchAllMeasurements();
  }

  NutritionEntry? getNutritionForDate(DateTime date) {
    final dateStr = _dateOnly(date);
    final matches = _nutritionEntries.where(
      (e) => _dateOnly(e.date) == dateStr,
    );
    return matches.isEmpty ? null : matches.first;
  }

  WeightEntry? getWeightForDate(DateTime date) {
    final dateStr = _dateOnly(date);
    final matches = _weightEntries.where((e) => _dateOnly(e.date) == dateStr);
    return matches.isEmpty ? null : matches.first;
  }

  String _dateOnly(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
