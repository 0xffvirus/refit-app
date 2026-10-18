import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_game/services/backup_codec.dart';

const _currentVersion = 6;

// Round-tripped through JSON so nested collections are mutable and dynamic,
// exactly like a decoded backup file.
Map<String, dynamic> _validBackup() =>
    jsonDecode(jsonEncode(_rawBackup())) as Map<String, dynamic>;

Map<String, Object?> _rawBackup() => {
  'version': 6,
  'exported_at': '2026-10-18T10:00:00.000',
  'habits': [
    {
      'id': 'h1',
      'name': 'Read',
      'sort_order': 0,
      'created_at': '2026-01-01T08:00:00.000',
    },
  ],
  'habit_entries': [
    {'id': 'he1', 'habit_id': 'h1', 'date': '2026-10-01', 'completed': 1},
  ],
  'daily_logs': [
    {'id': 'dl1', 'date': '2026-10-01', 'mood': 4, 'sleep_hours': 7.5},
  ],
  'fitness_weeks': [
    {
      'id': 'w1',
      'start_date': '2026-09-27',
      'end_date': '2026-10-03',
      'created_at': '2026-09-27T09:00:00.000',
    },
  ],
  'nutrition_entries': [
    {
      'id': 'n1',
      'week_id': 'w1',
      'date': '2026-09-28',
      'calories': 2000.0,
      'protein': 150,
      'carbs': 200.5,
      'fat': 60.0,
    },
  ],
  'weight_entries': [
    {'id': 'we1', 'week_id': 'w1', 'date': '2026-09-28', 'weight': 80.2},
  ],
  'weekly_assessments': [
    {
      'id': 'a1',
      'week_id': 'w1',
      'sleep_committed': 1,
      'calories_committed': 0,
      'progress': 'no_progress',
      'fatigue': 'low',
      'fluids_committed': 1,
      'steps_committed': 0,
    },
  ],
  'body_measurements': [
    {
      'id': 'b1',
      'week_id': 'w1',
      'chest': 100.0,
      'calves': 38.0,
      'waist': 85.0,
      'glutes': 98.0,
      'arm': 35.0,
      'thigh': 58.0,
      'front_photo_path': null,
      'back_photo_path': null,
    },
  ],
  'macro_targets': [
    {
      'id': 1,
      'calories': 2200.0,
      'protein': 160.0,
      'carbs': 220.0,
      'fat': 70.0,
    },
  ],
  'water_goal': [
    {'id': 1, 'daily_goal_ml': 3000},
  ],
  'water_entries': [
    {
      'id': 'wa1',
      'date': '2026-10-01',
      'amount_ml': 330,
      'created_at': '2026-10-01T09:00:00.000',
    },
  ],
  'step_entries': [
    {'id': 's1', 'week_id': 'w1', 'date': '2026-09-28', 'steps': 9000},
  ],
  'step_goal': [
    {'id': 1, 'daily_goal': 12000},
  ],
  'user_profile': [
    {
      'id': 1,
      'name': 'Sam',
      'gender': 'male',
      'age': 30,
      'height_cm': 180.0,
      'weight_kg': 80.0,
      'onboarding_seen': 1,
    },
  ],
};

ParsedBackup _parse(Object? json) =>
    parseBackup(jsonEncode(json), currentVersion: _currentVersion);

Matcher _throwsFormat(String fragment) => throwsA(
  isA<BackupFormatException>().having(
    (e) => e.message,
    'message',
    contains(fragment),
  ),
);

void main() {
  group('parseBackup accepts', () {
    test('a full current-version backup', () {
      final parsed = _parse(_validBackup());
      expect(parsed.version, 6);
      for (final table in backupTables) {
        expect(parsed.tables[table], hasLength(1), reason: table);
      }
      expect(parsed.tables['habits']!.first['name'], 'Read');
    });

    test('integral doubles in INTEGER columns and ints in REAL columns', () {
      final backup = _validBackup();
      (backup['water_goal'] as List).first['daily_goal_ml'] = 2500.0;
      (backup['daily_logs'] as List).first['sleep_hours'] = 8;
      final parsed = _parse(backup);
      expect(parsed.tables['water_goal']!.first['daily_goal_ml'], 2500);
      expect(parsed.tables['water_goal']!.first['daily_goal_ml'], isA<int>());
      expect(parsed.tables['daily_logs']!.first['sleep_hours'], 8.0);
    });

    test('a version 1 backup without later tables', () {
      final backup = _validBackup()..['version'] = 1;
      for (final t in [
        'macro_targets',
        'water_goal',
        'water_entries',
        'step_entries',
        'step_goal',
        'user_profile',
      ]) {
        backup.remove(t);
      }
      final parsed = _parse(backup);
      expect(parsed.version, 1);
      expect(parsed.tables.containsKey('user_profile'), isFalse);
      expect(parsed.tables['habits'], hasLength(1));
    });

    test('unknown top-level keys are ignored', () {
      final backup = _validBackup()..['some_future_note'] = 'x';
      expect(() => _parse(backup), returnsNormally);
    });
  });

  group('parseBackup rejects', () {
    test('malformed JSON', () {
      expect(
        () => parseBackup('{not json', currentVersion: _currentVersion),
        _throwsFormat('JSON'),
      );
    });

    test('a non-object root', () {
      expect(() => _parse([1, 2, 3]), _throwsFormat('object'));
    });

    test('a missing version', () {
      expect(
        () => _parse(_validBackup()..remove('version')),
        _throwsFormat('version'),
      );
    });

    test('a non-integer version', () {
      expect(
        () => _parse(_validBackup()..['version'] = '6'),
        _throwsFormat('version'),
      );
    });

    test('a version newer than the app supports', () {
      expect(
        () => _parse(_validBackup()..['version'] = 7),
        _throwsFormat('newer'),
      );
    });

    test('a version below 1', () {
      expect(
        () => _parse(_validBackup()..['version'] = 0),
        _throwsFormat('version'),
      );
    });

    test('a missing table that the backup version should contain', () {
      expect(
        () => _parse(_validBackup()..remove('water_goal')),
        _throwsFormat('water_goal'),
      );
    });

    test('a table that is not a list', () {
      expect(
        () => _parse(_validBackup()..['habits'] = {'id': 'h1'}),
        _throwsFormat('habits'),
      );
    });

    test('a row that is not an object', () {
      expect(
        () => _parse(_validBackup()..['habits'] = ['h1']),
        _throwsFormat('habits'),
      );
    });

    test('unknown columns', () {
      final backup = _validBackup();
      (backup['habits'] as List).first['drop_me'] = 1;
      expect(() => _parse(backup), _throwsFormat('drop_me'));
    });

    test('missing required columns', () {
      final backup = _validBackup();
      (backup['habits'] as List).first.remove('name');
      expect(() => _parse(backup), _throwsFormat('name'));
    });

    test('null in a NOT NULL column', () {
      final backup = _validBackup();
      (backup['weight_entries'] as List).first['weight'] = null;
      expect(() => _parse(backup), _throwsFormat('weight'));
    });

    test('wrong column types', () {
      final backup = _validBackup();
      (backup['step_entries'] as List).first['steps'] = 'many';
      expect(() => _parse(backup), _throwsFormat('steps'));
    });

    test('fractional values in INTEGER columns', () {
      final backup = _validBackup();
      (backup['water_entries'] as List).first['amount_ml'] = 330.5;
      expect(() => _parse(backup), _throwsFormat('amount_ml'));
    });

    test('unparseable dates', () {
      final backup = _validBackup();
      (backup['daily_logs'] as List).first['date'] = 'yesterday';
      expect(() => _parse(backup), _throwsFormat('date'));
    });

    test('more than one row in a singleton table', () {
      final backup = _validBackup();
      (backup['step_goal'] as List).add({'id': 1, 'daily_goal': 5000});
      expect(() => _parse(backup), _throwsFormat('step_goal'));
    });

    test('a singleton row whose id is not 1', () {
      final backup = _validBackup();
      (backup['macro_targets'] as List).first['id'] = 2;
      expect(() => _parse(backup), _throwsFormat('macro_targets'));
    });

    test('duplicate primary keys', () {
      final backup = _validBackup();
      final habits = backup['habits'] as List;
      habits.add(Map<String, dynamic>.from(habits.first));
      expect(() => _parse(backup), _throwsFormat('duplicate'));
    });

    test('child rows that reference a missing parent', () {
      final backup = _validBackup();
      (backup['habit_entries'] as List).first['habit_id'] = 'ghost';
      expect(() => _parse(backup), _throwsFormat('ghost'));

      final backup2 = _validBackup();
      (backup2['step_entries'] as List).first['week_id'] = 'nope';
      expect(() => _parse(backup2), _throwsFormat('nope'));
    });
  });

  test('singletonDefaults covers every singleton table with id 1', () {
    expect(singletonDefaults.keys.toSet(), singletonTables);
    for (final row in singletonDefaults.values) {
      expect(row['id'], 1);
    }
  });
}
