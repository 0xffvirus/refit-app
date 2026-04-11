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

class FitnessProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final HealthService _health = HealthService();
  final _uuid = const Uuid();

  List<FitnessWeek> _weeks = [];
  List<FitnessWeek> get weeks => _weeks;

  // Macro targets (persistent across weeks)
  Map<String, double> _macroTargets = {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
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
      'calories': _nutritionEntries.fold<double>(0, (a, e) => a + e.calories) / count,
      'protein': _nutritionEntries.fold<double>(0, (a, e) => a + e.protein) / count,
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

  Future<void> syncHealthData() async {
    await _health.syncCurrentWeek(
      existingWeeks: _weeks,
      createWeek: (startDate) async {
        final week = await _db.createFitnessWeek(startDate);
        _weeks = await _db.fetchAllFitnessWeeks();
        notifyListeners();
        return week;
      },
      loadWeekDetails: (weekId) async {
        await loadWeekDetails(weekId);
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
    _macroTargets = {'calories': calories, 'protein': protein, 'carbs': carbs, 'fat': fat};
    notifyListeners();
  }

  Future<void> updateStepGoal(int goal) async {
    await _db.updateStepGoal(goal);
    _stepGoal = goal;
    notifyListeners();
  }

  Future<void> loadWeekDetails(String weekId) async {
    _nutritionEntries = await _db.fetchNutritionForWeek(weekId);
    _weightEntries = await _db.fetchWeightsForWeek(weekId);
    _stepEntries = await _db.fetchStepsForWeek(weekId);
    _assessment = await _db.fetchAssessmentForWeek(weekId);
    _measurement = await _db.fetchMeasurementForWeek(weekId);
    notifyListeners();
  }

  Future<FitnessWeek> createWeek(DateTime startDate) async {
    final week = await _db.createFitnessWeek(startDate);
    _weeks = await _db.fetchAllFitnessWeeks();
    notifyListeners();
    return week;
  }

  Future<void> deleteWeek(String weekId) async {
    await _db.deleteFitnessWeek(weekId);
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
    _nutritionEntries = await _db.fetchNutritionForWeek(weekId);
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
    _weightEntries = await _db.fetchWeightsForWeek(weekId);
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
    _measurement = m;
    notifyListeners();
  }

  Future<List<BodyMeasurement>> fetchAllMeasurementsForComparison() async {
    return await _db.fetchAllMeasurements();
  }

  NutritionEntry? getNutritionForDate(DateTime date) {
    final dateStr = _dateOnly(date);
    final matches = _nutritionEntries.where((e) => _dateOnly(e.date) == dateStr);
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
