import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../models/habit_entry.dart';
import '../models/daily_log.dart';
import '../models/fitness_week.dart';
import '../models/nutrition_entry.dart';
import '../models/weight_entry.dart';
import '../models/weekly_assessment.dart';
import '../models/body_measurement.dart';
import '../models/water_entry.dart';
import '../models/step_entry.dart';

const _databaseName = 'habit_game.db';
const _databaseVersion = 5;

const _defaultHabits = [
  'Go to the gym',
  'Read for 15 min',
];

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final _uuid = const Uuid();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_entries (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_habit_entries_unique ON habit_entries (habit_id, date)
    ''');

    await db.execute('''
      CREATE TABLE daily_logs (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL UNIQUE,
        mood INTEGER NOT NULL,
        sleep_hours REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fitness_weeks (
        id TEXT PRIMARY KEY,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE nutrition_entries (
        id TEXT PRIMARY KEY,
        week_id TEXT NOT NULL,
        date TEXT NOT NULL,
        calories REAL NOT NULL DEFAULT 0,
        protein REAL NOT NULL DEFAULT 0,
        carbs REAL NOT NULL DEFAULT 0,
        fat REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (week_id) REFERENCES fitness_weeks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_nutrition_unique ON nutrition_entries (week_id, date)
    ''');

    await db.execute('''
      CREATE TABLE weight_entries (
        id TEXT PRIMARY KEY,
        week_id TEXT NOT NULL,
        date TEXT NOT NULL,
        weight REAL NOT NULL,
        FOREIGN KEY (week_id) REFERENCES fitness_weeks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_weight_unique ON weight_entries (week_id, date)
    ''');

    await db.execute('''
      CREATE TABLE weekly_assessments (
        id TEXT PRIMARY KEY,
        week_id TEXT NOT NULL UNIQUE,
        sleep_committed INTEGER NOT NULL DEFAULT 0,
        calories_committed INTEGER NOT NULL DEFAULT 0,
        progress TEXT NOT NULL DEFAULT 'no_progress',
        fatigue TEXT NOT NULL DEFAULT 'low',
        fluids_committed INTEGER NOT NULL DEFAULT 0,
        steps_committed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (week_id) REFERENCES fitness_weeks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE body_measurements (
        id TEXT PRIMARY KEY,
        week_id TEXT NOT NULL UNIQUE,
        chest REAL NOT NULL DEFAULT 0,
        calves REAL NOT NULL DEFAULT 0,
        waist REAL NOT NULL DEFAULT 0,
        glutes REAL NOT NULL DEFAULT 0,
        arm REAL NOT NULL DEFAULT 0,
        thigh REAL NOT NULL DEFAULT 0,
        front_photo_path TEXT,
        back_photo_path TEXT,
        FOREIGN KEY (week_id) REFERENCES fitness_weeks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE macro_targets (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        calories REAL NOT NULL DEFAULT 0,
        protein REAL NOT NULL DEFAULT 0,
        carbs REAL NOT NULL DEFAULT 0,
        fat REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.insert('macro_targets', {
      'id': 1,
      'calories': 0,
      'protein': 0,
      'carbs': 0,
      'fat': 0,
    });

    await db.execute('''
      CREATE TABLE water_goal (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        daily_goal_ml INTEGER NOT NULL DEFAULT 2500
      )
    ''');

    await db.insert('water_goal', {'id': 1, 'daily_goal_ml': 2500});

    await db.execute('''
      CREATE TABLE water_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        amount_ml INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_water_entries_date ON water_entries (date)
    ''');

    await db.execute('''
      CREATE TABLE step_entries (
        id TEXT PRIMARY KEY,
        week_id TEXT NOT NULL,
        date TEXT NOT NULL,
        steps INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (week_id) REFERENCES fitness_weeks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_step_entries_unique ON step_entries (week_id, date)
    ''');

    await db.execute('''
      CREATE TABLE step_goal (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        daily_goal INTEGER NOT NULL DEFAULT 10000
      )
    ''');

    await db.insert('step_goal', {'id': 1, 'daily_goal': 10000});

    // Seed default habits
    for (int i = 0; i < _defaultHabits.length; i++) {
      await db.insert('habits', {
        'id': const Uuid().v4(),
        'name': _defaultHabits[i],
        'sort_order': i,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS macro_targets (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          calories REAL NOT NULL DEFAULT 0,
          protein REAL NOT NULL DEFAULT 0,
          carbs REAL NOT NULL DEFAULT 0,
          fat REAL NOT NULL DEFAULT 0
        )
      ''');
      await db.insert('macro_targets', {
        'id': 1,
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fat': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS water_goal (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          daily_goal_ml INTEGER NOT NULL DEFAULT 2500
        )
      ''');
      await db.insert('water_goal', {'id': 1, 'daily_goal_ml': 2500},
          conflictAlgorithm: ConflictAlgorithm.ignore);

      await db.execute('''
        CREATE TABLE IF NOT EXISTS water_entries (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          amount_ml INTEGER NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_water_entries_date ON water_entries (date)
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS step_entries (
          id TEXT PRIMARY KEY,
          week_id TEXT NOT NULL,
          date TEXT NOT NULL,
          steps INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (week_id) REFERENCES fitness_weeks (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_step_entries_unique ON step_entries (week_id, date)
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS step_goal (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          daily_goal INTEGER NOT NULL DEFAULT 10000
        )
      ''');
      await db.insert('step_goal', {'id': 1, 'daily_goal': 10000},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ── Macro Targets ──

  Future<Map<String, double>> fetchMacroTargets() async {
    final db = await database;
    final rows = await db.query('macro_targets', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }
    final row = rows.first;
    return {
      'calories': (row['calories'] as num).toDouble(),
      'protein': (row['protein'] as num).toDouble(),
      'carbs': (row['carbs'] as num).toDouble(),
      'fat': (row['fat'] as num).toDouble(),
    };
  }

  Future<void> updateMacroTargets({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    final db = await database;
    await db.update(
      'macro_targets',
      {'calories': calories, 'protein': protein, 'carbs': carbs, 'fat': fat},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ── Step Goal ──

  Future<int> fetchStepGoal() async {
    final db = await database;
    final rows = await db.query('step_goal', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return 10000;
    return (rows.first['daily_goal'] as int?) ?? 10000;
  }

  Future<void> updateStepGoal(int goal) async {
    final db = await database;
    await db.update(
      'step_goal',
      {'daily_goal': goal},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ── Habits ──

  Future<List<Habit>> fetchAllHabits() async {
    final db = await database;
    final rows = await db.query('habits', orderBy: 'sort_order ASC');
    return rows.map((r) => Habit.fromMap(r)).toList();
  }

  Future<void> insertHabit(Habit habit) async {
    final db = await database;
    await db.insert('habits', habit.toMap());
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await database;
    await db.update('habits', habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<void> deleteHabit(String habitId) async {
    final db = await database;
    await db.delete('habits', where: 'id = ?', whereArgs: [habitId]);
  }

  Future<void> reorderHabits(List<Habit> habits) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < habits.length; i++) {
      batch.update(
        'habits',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [habits[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  // ── Habit Entries ──

  Future<List<HabitEntry>> fetchHabitEntriesForMonth(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final endDate = '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    final rows = await db.query(
      'habit_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
    );
    return rows.map((r) => HabitEntry.fromMap(r)).toList();
  }

  Future<void> toggleHabitEntry({
    required String habitId,
    required DateTime date,
  }) async {
    final db = await database;
    final dateStr = _dateOnly(date);

    final existing = await db.query(
      'habit_entries',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, dateStr],
    );

    if (existing.isEmpty) {
      await db.insert('habit_entries', {
        'id': _uuid.v4(),
        'habit_id': habitId,
        'date': dateStr,
        'completed': 1,
      });
    } else {
      final current = (existing.first['completed'] as int) == 1;
      await db.update(
        'habit_entries',
        {'completed': current ? 0 : 1},
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, dateStr],
      );
    }
  }

  // ── Daily Logs ──

  Future<List<DailyLog>> fetchDailyLogsForMonth(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final endDate = '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    final rows = await db.query(
      'daily_logs',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
    );
    return rows.map((r) => DailyLog.fromMap(r)).toList();
  }

  Future<void> upsertDailyLog(DailyLog log) async {
    final db = await database;
    await db.insert(
      'daily_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Fitness Weeks ──

  Future<List<FitnessWeek>> fetchAllFitnessWeeks() async {
    final db = await database;
    final rows = await db.query('fitness_weeks', orderBy: 'start_date DESC');
    return rows.map((r) => FitnessWeek.fromMap(r)).toList();
  }

  Future<FitnessWeek> createFitnessWeek(DateTime startDate) async {
    final db = await database;
    final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

    // Return existing week if one with the same start date exists
    final existing = await db.query(
      'fitness_weeks',
      where: 'start_date = ?',
      whereArgs: [startStr],
    );
    if (existing.isNotEmpty) {
      return FitnessWeek.fromMap(existing.first);
    }

    final endDate = startDate.add(const Duration(days: 6));
    final week = FitnessWeek(
      id: _uuid.v4(),
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
    );
    await db.insert('fitness_weeks', week.toMap());
    return week;
  }

  Future<void> deleteFitnessWeek(String weekId) async {
    final db = await database;
    await db.delete('fitness_weeks', where: 'id = ?', whereArgs: [weekId]);
  }

  // ── Nutrition Entries ──

  Future<List<NutritionEntry>> fetchNutritionForWeek(String weekId) async {
    final db = await database;
    final rows = await db.query(
      'nutrition_entries',
      where: 'week_id = ?',
      whereArgs: [weekId],
      orderBy: 'date ASC',
    );
    return rows.map((r) => NutritionEntry.fromMap(r)).toList();
  }

  Future<void> upsertNutritionEntry(NutritionEntry entry) async {
    final db = await database;
    await db.insert(
      'nutrition_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Weight Entries ──

  Future<List<WeightEntry>> fetchWeightsForWeek(String weekId) async {
    final db = await database;
    final rows = await db.query(
      'weight_entries',
      where: 'week_id = ?',
      whereArgs: [weekId],
      orderBy: 'date ASC',
    );
    return rows.map((r) => WeightEntry.fromMap(r)).toList();
  }

  Future<void> upsertWeightEntry(WeightEntry entry) async {
    final db = await database;
    await db.insert(
      'weight_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Weekly Assessment ──

  Future<WeeklyAssessment?> fetchAssessmentForWeek(String weekId) async {
    final db = await database;
    final rows = await db.query(
      'weekly_assessments',
      where: 'week_id = ?',
      whereArgs: [weekId],
    );
    if (rows.isEmpty) return null;
    return WeeklyAssessment.fromMap(rows.first);
  }

  Future<void> upsertWeeklyAssessment(WeeklyAssessment assessment) async {
    final db = await database;
    await db.insert(
      'weekly_assessments',
      assessment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Body Measurements ──

  Future<BodyMeasurement?> fetchMeasurementForWeek(String weekId) async {
    final db = await database;
    final rows = await db.query(
      'body_measurements',
      where: 'week_id = ?',
      whereArgs: [weekId],
    );
    if (rows.isEmpty) return null;
    return BodyMeasurement.fromMap(rows.first);
  }

  Future<void> upsertBodyMeasurement(BodyMeasurement measurement) async {
    final db = await database;
    await db.insert(
      'body_measurements',
      measurement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BodyMeasurement>> fetchAllMeasurements() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT bm.* FROM body_measurements bm
      JOIN fitness_weeks fw ON bm.week_id = fw.id
      ORDER BY fw.start_date ASC
    ''');
    return rows.map((r) => BodyMeasurement.fromMap(r)).toList();
  }

  // ── Gamification helpers ──

  Future<int> fetchCurrentStreak(String habitId) async {
    final db = await database;
    final rows = await db.query(
      'habit_entries',
      where: 'habit_id = ? AND completed = 1',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );

    if (rows.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();
    final dateStr = _dateOnly(checkDate);

    // Check if today is completed; if not, start from yesterday
    final todayEntry = rows.where((r) => r['date'] == dateStr).toList();
    if (todayEntry.isEmpty) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    final completedDates = rows.map((r) => r['date'] as String).toSet();

    while (completedDates.contains(_dateOnly(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  String _dateOnly(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  // ── Step Entries ──

  Future<List<StepEntry>> fetchStepsForWeek(String weekId) async {
    final db = await database;
    final rows = await db.query(
      'step_entries',
      where: 'week_id = ?',
      whereArgs: [weekId],
      orderBy: 'date ASC',
    );
    return rows.map((r) => StepEntry.fromMap(r)).toList();
  }

  Future<void> upsertStepEntry(StepEntry entry) async {
    final db = await database;
    await db.insert(
      'step_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Water Tracking ──

  Future<int> fetchWaterGoal() async {
    final db = await database;
    final rows = await db.query('water_goal', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return 2500;
    return rows.first['daily_goal_ml'] as int;
  }

  Future<void> updateWaterGoal(int goalMl) async {
    final db = await database;
    await db.update('water_goal', {'daily_goal_ml': goalMl},
        where: 'id = ?', whereArgs: [1]);
  }

  Future<List<WaterEntry>> fetchWaterEntriesForDate(DateTime date) async {
    final db = await database;
    final dateStr = _dateOnly(date);
    final rows = await db.query(
      'water_entries',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => WaterEntry.fromMap(r)).toList();
  }

  Future<void> insertWaterEntry(WaterEntry entry) async {
    final db = await database;
    await db.insert('water_entries', entry.toMap());
  }

  Future<void> deleteWaterEntry(String id) async {
    final db = await database;
    await db.delete('water_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ── Backup & Restore ──

  static const _backupTables = [
    'habits',
    'habit_entries',
    'daily_logs',
    'fitness_weeks',
    'nutrition_entries',
    'weight_entries',
    'weekly_assessments',
    'body_measurements',
    'macro_targets',
    'water_goal',
    'water_entries',
    'step_entries',
    'step_goal',
  ];

  Future<String> exportToJson() async {
    final db = await database;
    final Map<String, dynamic> backup = {
      'version': _databaseVersion,
      'exported_at': DateTime.now().toIso8601String(),
    };

    for (final table in _backupTables) {
      final rows = await db.query(table);
      backup[table] = rows;
    }

    return jsonEncode(backup);
  }

  Future<File> exportToFile() async {
    final jsonStr = await exportToJson();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File(p.join(dir.path, 'habit_game_backup_$timestamp.json'));
    await file.writeAsString(jsonStr);
    return file;
  }

  Future<void> importFromJson(String jsonStr) async {
    final Map<String, dynamic> backup = jsonDecode(jsonStr) as Map<String, dynamic>;
    final db = await database;

    await db.transaction((txn) async {
      // Clear all existing data in reverse dependency order
      for (final table in _backupTables.reversed) {
        await txn.delete(table);
      }

      // Restore each table
      for (final table in _backupTables) {
        final rows = backup[table] as List<dynamic>?;
        if (rows == null) continue;

        for (final row in rows) {
          await txn.insert(
            table,
            Map<String, dynamic>.from(row as Map),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<void> importFromFile(File file) async {
    final jsonStr = await file.readAsString();
    await importFromJson(jsonStr);
  }
}
