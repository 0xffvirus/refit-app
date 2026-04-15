import 'dart:io';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/nutrition_entry.dart';
import '../models/weight_entry.dart';
import '../models/daily_log.dart';
import '../models/step_entry.dart';
import '../models/fitness_week.dart';
import 'database_service.dart';

const _healthEnabledKey = 'health_sync_enabled';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final _uuid = const Uuid();
  final _db = DatabaseService();

  static const _types = [
    HealthDataType.DIETARY_ENERGY_CONSUMED,
    HealthDataType.DIETARY_PROTEIN_CONSUMED,
    HealthDataType.DIETARY_CARBS_CONSUMED,
    HealthDataType.DIETARY_FATS_CONSUMED,
    HealthDataType.WEIGHT,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.STEPS,
    HealthDataType.WATER,
  ];

  static const _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ_WRITE,
  ];

  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_healthEnabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_healthEnabledKey, value);
  }

  Future<bool> requestPermissions() async {
    if (!Platform.isIOS) return false;

    try {
      Health().configure();
      final granted = await Health().requestAuthorization(_types, permissions: _permissions);
      return granted;
    } catch (e) {
      return false;
    }
  }

  Future<void> syncCurrentWeek({
    required List<FitnessWeek> existingWeeks,
    required Future<FitnessWeek> Function(DateTime startDate) createWeek,
    required Future<void> Function(String weekId) loadWeekDetails,
  }) async {
    if (!Platform.isIOS) return;

    final enabled = await isEnabled;
    if (!enabled) return;

    Health().configure();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find or create the current week (Sunday-based)
    final weekday = today.weekday; // Monday=1, Sunday=7
    final sundayOffset = weekday == 7 ? 0 : weekday;
    final weekStart = today.subtract(Duration(days: sundayOffset));
    final weekEnd = weekStart.add(const Duration(days: 6));

    FitnessWeek? currentWeek;
    final weekStartStr = _dateOnly(weekStart);
    for (final w in existingWeeks) {
      if (_dateOnly(w.startDate) == weekStartStr) {
        currentWeek = w;
        break;
      }
    }

    currentWeek ??= await createWeek(weekStart);
    final weekId = currentWeek.id;

    // Sync each day of the current week up to today
    for (var d = weekStart; !d.isAfter(today) && !d.isAfter(weekEnd); d = d.add(const Duration(days: 1))) {
      await _syncDayData(weekId, d);
    }

    await loadWeekDetails(weekId);
  }

  Future<void> _syncDayData(String weekId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

    await Future.wait([
      _syncNutrition(weekId, date, start, end),
      _syncWeight(weekId, date, start, end),
      _syncSleep(date, start, end),
      _syncSteps(weekId, date, start, end),
    ]);
  }

  Future<void> _syncNutrition(String weekId, DateTime date, DateTime start, DateTime end) async {
    try {
      final caloriesData = await Health().getHealthDataFromTypes(
        startTime: start, endTime: end,
        types: [HealthDataType.DIETARY_ENERGY_CONSUMED],
      );
      final proteinData = await Health().getHealthDataFromTypes(
        startTime: start, endTime: end,
        types: [HealthDataType.DIETARY_PROTEIN_CONSUMED],
      );
      final carbsData = await Health().getHealthDataFromTypes(
        startTime: start, endTime: end,
        types: [HealthDataType.DIETARY_CARBS_CONSUMED],
      );
      final fatData = await Health().getHealthDataFromTypes(
        startTime: start, endTime: end,
        types: [HealthDataType.DIETARY_FATS_CONSUMED],
      );

      final calories = _sumNumericValues(caloriesData);
      final protein = _sumNumericValues(proteinData);
      final carbs = _sumNumericValues(carbsData);
      final fat = _sumNumericValues(fatData);

      if (calories > 0 || protein > 0 || carbs > 0 || fat > 0) {
        await _db.upsertNutritionEntry(NutritionEntry(
          id: _uuid.v4(),
          weekId: weekId,
          date: date,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
        ));
      }
    } catch (_) {}
  }

  Future<void> _syncWeight(String weekId, DateTime date, DateTime start, DateTime end) async {
    try {
      final data = await Health().getHealthDataFromTypes(
        startTime: start, endTime: end,
        types: [HealthDataType.WEIGHT],
      );

      if (data.isNotEmpty) {
        final latest = data.last;
        final value = (latest.value as NumericHealthValue).numericValue.toDouble();
        if (value > 0) {
          await _db.upsertWeightEntry(WeightEntry(
            id: _uuid.v4(),
            weekId: weekId,
            date: date,
            weight: value,
          ));
        }
      }
    } catch (_) {}
  }

  Future<void> _syncSleep(DateTime date, DateTime start, DateTime end) async {
    try {
      // Look at the night before: from previous day 8pm to this day noon
      final sleepStart = DateTime(date.year, date.month, date.day - 1, 20);
      final sleepEnd = DateTime(date.year, date.month, date.day, 12);

      final data = await Health().getHealthDataFromTypes(
        startTime: sleepStart, endTime: sleepEnd,
        types: [HealthDataType.SLEEP_ASLEEP],
      );

      if (data.isNotEmpty) {
        double totalMinutes = 0;
        for (final d in data) {
          totalMinutes += d.dateTo.difference(d.dateFrom).inMinutes;
        }
        final hours = totalMinutes / 60;
        if (hours > 0) {
          await _db.upsertDailyLog(DailyLog(
            id: _uuid.v4(),
            date: date,
            mood: 3, // neutral default
            sleepHours: double.parse(hours.toStringAsFixed(1)),
          ));
        }
      }
    } catch (_) {}
  }

  Future<void> _syncSteps(String weekId, DateTime date, DateTime start, DateTime end) async {
    try {
      final data = await Health().getHealthDataFromTypes(
        startTime: start, endTime: end,
        types: [HealthDataType.STEPS],
      );

      final totalSteps = _sumNumericValues(data).toInt();
      if (totalSteps > 0) {
        await _db.upsertStepEntry(StepEntry(
          id: _uuid.v4(),
          weekId: weekId,
          date: date,
          steps: totalSteps,
        ));
      }
    } catch (_) {}
  }

  Future<bool> writeWaterIntake(int amountMl, DateTime date) async {
    if (!Platform.isIOS) return false;

    final enabled = await isEnabled;
    if (!enabled) return false;

    try {
      Health().configure();
      final now = DateTime.now();
      return await Health().writeHealthData(
        value: amountMl / 1000.0, // convert ml to liters
        type: HealthDataType.WATER,
        unit: HealthDataUnit.LITER,
        startTime: now,
        endTime: now,
      );
    } catch (_) {
      return false;
    }
  }

  double _sumNumericValues(List<HealthDataPoint> data) {
    double sum = 0;
    for (final point in data) {
      if (point.value is NumericHealthValue) {
        sum += (point.value as NumericHealthValue).numericValue.toDouble();
      }
    }
    return sum;
  }

  String _dateOnly(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
