import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_game/models/habit.dart';
import 'package:habit_game/models/user_profile.dart';
import 'package:habit_game/models/weight_entry.dart';
import 'package:habit_game/services/backup_codec.dart';
import 'package:habit_game/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseService.resetForTesting(path: inMemoryDatabasePath);
    db = DatabaseService();
  });

  tearDown(() async {
    await DatabaseService.resetForTesting();
  });

  Future<Map<String, dynamic>> exportMap() async =>
      jsonDecode(await db.exportToJson()) as Map<String, dynamic>;

  Future<void> seedSampleData() async {
    // Import always marks onboarding seen; match that so round-trips compare.
    await db.updateUserProfile(UserProfile(name: 'Sam', onboardingSeen: true));
    await db.insertHabit(
      Habit(
        id: 'h-extra',
        name: 'Stretch',
        sortOrder: 5,
        createdAt: DateTime(2026, 10, 1),
      ),
    );
    await db.toggleHabitEntry(habitId: 'h-extra', date: DateTime(2026, 10, 2));
    final week = await db.createFitnessWeek(DateTime(2026, 9, 27));
    await db.upsertWeightEntry(
      WeightEntry(
        id: 'w-entry',
        weekId: week.id,
        date: DateTime(2026, 9, 28),
        weight: 81.5,
      ),
    );
    await db.updateWaterGoal(3200);
    await db.updateStepGoal(12345);
    await db.updateMacroTargets(
      calories: 2100,
      protein: 150,
      carbs: 210,
      fat: 65,
    );
  }

  test('export → import round-trips a current backup exactly', () async {
    await seedSampleData();
    final exported = await db.exportToJson();
    final before = await exportMap();

    // Mutate the DB so the import has something to overwrite.
    await db.updateWaterGoal(1000);
    await db.deleteHabit('h-extra');

    await db.importFromJson(exported);
    final after = await exportMap();

    for (final table in backupTables) {
      expect(after[table], before[table], reason: table);
    }
  });

  test('invalid backups are rejected before any data is touched', () async {
    await seedSampleData();
    final before = await exportMap();

    final bad = Map<String, dynamic>.from(before);
    bad['habit_entries'] = [
      {'id': 'x', 'habit_id': 'missing', 'date': '2026-10-01', 'completed': 1},
    ];

    await expectLater(
      db.importFromJson(jsonEncode(bad)),
      throwsA(isA<BackupFormatException>()),
    );

    final after = await exportMap();
    for (final table in backupTables) {
      expect(after[table], before[table], reason: table);
    }
  });

  test(
    'a database error mid-import rolls back the whole transaction',
    () async {
      await seedSampleData();
      final before = await exportMap();

      // Valid per the codec, but violates the UNIQUE(habit_id, date) index.
      final bad = Map<String, dynamic>.from(before);
      final habitId = (before['habits'] as List).first['id'];
      bad['habit_entries'] = [
        {'id': 'e1', 'habit_id': habitId, 'date': '2026-10-01', 'completed': 1},
        {'id': 'e2', 'habit_id': habitId, 'date': '2026-10-01', 'completed': 0},
      ];

      await expectLater(db.importFromJson(jsonEncode(bad)), throwsA(anything));

      final after = await exportMap();
      for (final table in backupTables) {
        expect(after[table], before[table], reason: table);
      }
    },
  );

  test('older backups recreate missing singleton rows with defaults', () async {
    await seedSampleData();
    final v1 = <String, dynamic>{
      'version': 1,
      'habits': [
        {
          'id': 'old',
          'name': 'Old habit',
          'sort_order': 0,
          'created_at': '2025-01-01T00:00:00.000',
        },
      ],
      'habit_entries': [],
      'daily_logs': [],
      'fitness_weeks': [],
      'nutrition_entries': [],
      'weight_entries': [],
      'weekly_assessments': [],
      'body_measurements': [],
    };

    await db.importFromJson(jsonEncode(v1));

    expect((await db.fetchAllHabits()).map((h) => h.name), ['Old habit']);
    expect(await db.fetchWaterGoal(), 2500);
    expect(await db.fetchStepGoal(), 10000);
    expect(await db.fetchMacroTargets(), {
      'calories': 0.0,
      'protein': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
    });
    final profile = await db.fetchUserProfile();
    expect(profile.onboardingSeen, isTrue);

    // Singleton updates must still work after the import.
    await db.updateWaterGoal(2800);
    expect(await db.fetchWaterGoal(), 2800);
    await db.updateStepGoal(7000);
    expect(await db.fetchStepGoal(), 7000);
  });

  test(
    'an empty singleton list in a backup still leaves a default row',
    () async {
      final backup = await exportMap();
      backup['water_goal'] = [];
      backup['user_profile'] = [];

      await db.importFromJson(jsonEncode(backup));

      expect(await db.fetchWaterGoal(), 2500);
      await db.updateWaterGoal(1800);
      expect(await db.fetchWaterGoal(), 1800);
      expect((await db.fetchUserProfile()).onboardingSeen, isTrue);
    },
  );

  test('partial singleton rows are merged over defaults', () async {
    final backup = await exportMap();
    backup['user_profile'] = [
      {'id': 1, 'name': 'Lee'},
    ];

    await db.importFromJson(jsonEncode(backup));

    final profile = await db.fetchUserProfile();
    expect(profile.name, 'Lee');
    expect(profile.onboardingSeen, isTrue);
  });

  test(
    'import marks onboarding as seen even if the backup says otherwise',
    () async {
      final backup = await exportMap();
      (backup['user_profile'] as List).first['onboarding_seen'] = 0;

      await db.importFromJson(jsonEncode(backup));

      expect((await db.fetchUserProfile()).onboardingSeen, isTrue);
    },
  );
}
