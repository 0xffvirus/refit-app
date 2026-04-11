import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/water_entry.dart';
import '../services/database_service.dart';
import '../services/health_service.dart';

class WaterProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final HealthService _health = HealthService();
  final _uuid = const Uuid();

  int _dailyGoalMl = 2500;
  List<WaterEntry> _entries = [];
  DateTime _selectedDate = DateTime.now();
  bool _initialized = false;

  int get dailyGoalMl => _dailyGoalMl;
  List<WaterEntry> get entries => _entries;
  DateTime get selectedDate => _selectedDate;
  bool get initialized => _initialized;

  int get totalMl {
    return _entries.fold<int>(0, (sum, e) => sum + e.amountMl);
  }

  double get percentage {
    if (_dailyGoalMl <= 0) return 0;
    return (totalMl / _dailyGoalMl).clamp(0.0, 1.0);
  }

  bool get goalReached => totalMl >= _dailyGoalMl;

  Future<void> initialize() async {
    _dailyGoalMl = await _db.fetchWaterGoal();
    await _loadEntries();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadEntries() async {
    _entries = await _db.fetchWaterEntriesForDate(_selectedDate);
  }

  Future<void> addWater(int amountMl) async {
    final entry = WaterEntry(
      id: _uuid.v4(),
      date: _selectedDate,
      amountMl: amountMl,
      createdAt: DateTime.now(),
    );
    await _db.insertWaterEntry(entry);
    _health.writeWaterIntake(amountMl, _selectedDate);
    await _loadEntries();
    notifyListeners();
  }

  Future<void> removeEntry(String id) async {
    await _db.deleteWaterEntry(id);
    await _loadEntries();
    notifyListeners();
  }

  Future<void> setGoal(int goalMl) async {
    _dailyGoalMl = goalMl;
    await _db.updateWaterGoal(goalMl);
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    _loadEntries().then((_) => notifyListeners());
  }
}
