import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/water_entry.dart';
import '../services/database_service.dart';
import '../services/health_service.dart';
import '../services/notification_service.dart';
import '../utils/request_sequencer.dart';

class WaterProvider extends ChangeNotifier {
  WaterProvider({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _selectedDate = _clock();
  }

  final DatabaseService _db = DatabaseService();
  final HealthService _health = HealthService();
  final NotificationService _notifications = NotificationService();
  final _uuid = const Uuid();
  final DateTime Function() _clock;
  final _loads = RequestSequencer();
  bool _disposed = false;
  Timer? _midnightTimer;

  int _dailyGoalMl = 2500;
  List<WaterEntry> _entries = [];
  late DateTime _selectedDate;
  // True while the selected date should track "today" across midnight.
  bool _followsToday = true;
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

  @override
  void dispose() {
    _disposed = true;
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> initialize() async {
    _rollToTodayIfNeeded();
    _dailyGoalMl = await _db.fetchWaterGoal();
    await _loadEntries();
    _initialized = true;
    _scheduleMidnightRefresh();
    notifyListeners();
  }

  /// Rolls the day over at local midnight while the app stays in the
  /// foreground. Resume is handled separately by [refreshForToday], since
  /// timers don't fire while the app is suspended.
  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = _clock();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      () {
        refreshForToday();
        _scheduleMidnightRefresh();
      },
    );
  }

  /// Moves the selected date to today if the calendar day changed since it
  /// was set (e.g. the app was resumed after midnight) and reloads entries.
  Future<void> refreshForToday() async {
    if (!_rollToTodayIfNeeded()) return;
    await _loadEntries();
    notifyListeners();
  }

  bool _rollToTodayIfNeeded() {
    final now = _clock();
    if (!_followsToday || isSameDay(_selectedDate, now)) return false;
    _selectedDate = now;
    return true;
  }

  Future<void> _loadEntries() async {
    final token = _loads.next();
    final entries = await _db.fetchWaterEntriesForDate(_selectedDate);
    if (_loads.isCurrent(token)) _entries = entries;
  }

  Future<void> addWater(int amountMl) async {
    _rollToTodayIfNeeded();
    final entry = WaterEntry(
      id: _uuid.v4(),
      date: _selectedDate,
      amountMl: amountMl,
      createdAt: _clock(),
    );
    await _db.insertWaterEntry(entry);
    _health.writeWaterIntake(amountMl, _selectedDate);
    // Suppress the next reminder if it's within the hour — user just hydrated.
    _notifications.rescheduleAfterLog();
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

  Future<void> setDate(DateTime date) async {
    _selectedDate = date;
    _followsToday = isSameDay(date, _clock());
    await _loadEntries();
    notifyListeners();
  }
}
