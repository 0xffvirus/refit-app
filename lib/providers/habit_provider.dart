import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../models/habit_entry.dart';
import '../models/daily_log.dart';
import '../services/database_service.dart';

class HabitProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  List<Habit> _habits = [];
  List<HabitEntry> _entries = [];
  List<DailyLog> _dailyLogs = [];
  Map<String, int> _streaks = {};

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  List<Habit> get habits => _habits;
  List<HabitEntry> get entries => _entries;
  List<DailyLog> get dailyLogs => _dailyLogs;
  Map<String, int> get streaks => _streaks;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;

  int get daysInMonth => DateTime(_selectedYear, _selectedMonth + 1, 0).day;

  Future<void> initialize() async {
    _habits = await _db.fetchAllHabits();
    await _loadMonthData();
    await _loadStreaks();
    notifyListeners();
  }

  Future<void> _loadMonthData() async {
    _entries = await _db.fetchHabitEntriesForMonth(_selectedYear, _selectedMonth);
    _dailyLogs = await _db.fetchDailyLogsForMonth(_selectedYear, _selectedMonth);
  }

  Future<void> _loadStreaks() async {
    final Map<String, int> newStreaks = {};
    for (final habit in _habits) {
      newStreaks[habit.id] = await _db.fetchCurrentStreak(habit.id);
    }
    _streaks = newStreaks;
  }

  void setMonth(int year, int month) {
    _selectedYear = year;
    _selectedMonth = month;
    _loadMonthData().then((_) => notifyListeners());
  }

  bool isHabitCompletedOn(String habitId, int day) {
    final dateStr = _formatDate(_selectedYear, _selectedMonth, day);
    return _entries.any(
      (e) => e.habitId == habitId && _dateOnly(e.date) == dateStr && e.completed,
    );
  }

  bool isHabitCompletedOnDate(String habitId, DateTime date) {
    final dateStr = _dateOnly(date);
    return _entries.any(
      (e) => e.habitId == habitId && _dateOnly(e.date) == dateStr && e.completed,
    );
  }

  int completedCountForDate(DateTime date) {
    int count = 0;
    for (final h in _habits) {
      if (isHabitCompletedOnDate(h.id, date)) count++;
    }
    return count;
  }

  Future<void> toggleHabit(String habitId, int day) async {
    final date = DateTime(_selectedYear, _selectedMonth, day);
    await _db.toggleHabitEntry(habitId: habitId, date: date);
    await _loadMonthData();
    await _loadStreaks();
    notifyListeners();
  }

  Future<void> toggleHabitForDate(String habitId, DateTime date) async {
    await _db.toggleHabitEntry(habitId: habitId, date: date);
    await _loadMonthData();
    await _loadStreaks();
    notifyListeners();
  }

  Future<void> addHabit(String name) async {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      sortOrder: _habits.length,
      createdAt: DateTime.now(),
    );
    await _db.insertHabit(habit);
    _habits = await _db.fetchAllHabits();
    notifyListeners();
  }

  Future<void> removeHabit(String habitId) async {
    await _db.deleteHabit(habitId);
    _habits = await _db.fetchAllHabits();
    await _loadMonthData();
    notifyListeners();
  }

  Future<void> reorderHabits(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final habit = _habits.removeAt(oldIndex);
    _habits.insert(newIndex, habit);
    await _db.reorderHabits(_habits);
    notifyListeners();
  }

  Future<void> saveDailyLog({
    required DateTime date,
    required int mood,
    required double sleepHours,
  }) async {
    final log = DailyLog(
      id: _uuid.v4(),
      date: date,
      mood: mood,
      sleepHours: sleepHours,
    );
    await _db.upsertDailyLog(log);
    _dailyLogs = await _db.fetchDailyLogsForMonth(_selectedYear, _selectedMonth);
    notifyListeners();
  }

  DailyLog? getDailyLogForDay(int day) {
    final dateStr = _formatDate(_selectedYear, _selectedMonth, day);
    final matches = _dailyLogs.where((l) => _dateOnly(l.date) == dateStr);
    return matches.isEmpty ? null : matches.first;
  }

  DailyLog? getDailyLogForDate(DateTime date) {
    final dateStr = _dateOnly(date);
    final matches = _dailyLogs.where((l) => _dateOnly(l.date) == dateStr);
    return matches.isEmpty ? null : matches.first;
  }

  // ── Statistics ──

  double habitCompletionRate(String habitId) {
    final totalDays = daysInMonth;
    final today = DateTime.now();
    final maxDay = (_selectedYear == today.year && _selectedMonth == today.month)
        ? today.day
        : totalDays;

    if (maxDay == 0) return 0;

    int completed = 0;
    for (int d = 1; d <= maxDay; d++) {
      if (isHabitCompletedOn(habitId, d)) completed++;
    }
    return completed / maxDay;
  }

  double overallCompletionRate() {
    if (_habits.isEmpty) return 0;
    double sum = 0;
    for (final h in _habits) {
      sum += habitCompletionRate(h.id);
    }
    return sum / _habits.length;
  }

  List<MapEntry<Habit, double>> habitRanking() {
    final ranked = _habits.map((h) => MapEntry(h, habitCompletionRate(h.id))).toList();
    ranked.sort((a, b) => b.value.compareTo(a.value));
    return ranked;
  }

  double dailyCompletionRate(int day) {
    if (_habits.isEmpty) return 0;
    int completed = 0;
    for (final h in _habits) {
      if (isHabitCompletedOn(h.id, day)) completed++;
    }
    return completed / _habits.length;
  }

  String _formatDate(int year, int month, int day) {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  String _dateOnly(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
