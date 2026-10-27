import 'dart:convert';

/// Validation for JSON backups produced by [DatabaseService.exportToJson].
///
/// Kept free of sqflite so it can be unit-tested in isolation. Everything is
/// checked before the database is touched, so a bad file never wipes data.

class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);

  @override
  String toString() => 'BackupFormatException: $message';
}

enum _ColType { text, integer, real }

class _Col {
  final _ColType type;
  final bool nullable;
  final bool isDate;
  const _Col(this.type, {this.nullable = false, this.isDate = false});
}

const _text = _Col(_ColType.text);
const _textNullable = _Col(_ColType.text, nullable: true);
const _date = _Col(_ColType.text, isDate: true);
const _int = _Col(_ColType.integer);
const _intNullable = _Col(_ColType.integer, nullable: true);
const _real = _Col(_ColType.real);
const _realNullable = _Col(_ColType.real, nullable: true);

class _TableSpec {
  /// Schema version that introduced this table.
  final int sinceVersion;
  final Map<String, _Col> columns;

  /// Columns that must be present in every row. Columns with a SQL default
  /// may be omitted.
  final Set<String> required;

  /// Foreign keys: column → parent table (referencing the parent's `id`).
  final Map<String, String> references;

  const _TableSpec({
    required this.sinceVersion,
    required this.columns,
    required this.required,
    this.references = const {},
  });
}

const _specs = <String, _TableSpec>{
  'habits': _TableSpec(
    sinceVersion: 1,
    columns: {
      'id': _text,
      'name': _text,
      'sort_order': _int,
      'created_at': _date,
    },
    required: {'id', 'name', 'sort_order', 'created_at'},
  ),
  'habit_entries': _TableSpec(
    sinceVersion: 1,
    columns: {'id': _text, 'habit_id': _text, 'date': _date, 'completed': _int},
    required: {'id', 'habit_id', 'date'},
    references: {'habit_id': 'habits'},
  ),
  'daily_logs': _TableSpec(
    sinceVersion: 1,
    columns: {'id': _text, 'date': _date, 'mood': _int, 'sleep_hours': _real},
    required: {'id', 'date', 'mood', 'sleep_hours'},
  ),
  'fitness_weeks': _TableSpec(
    sinceVersion: 1,
    columns: {
      'id': _text,
      'start_date': _date,
      'end_date': _date,
      'created_at': _date,
    },
    required: {'id', 'start_date', 'end_date', 'created_at'},
  ),
  'nutrition_entries': _TableSpec(
    sinceVersion: 1,
    columns: {
      'id': _text,
      'week_id': _text,
      'date': _date,
      'calories': _real,
      'protein': _real,
      'carbs': _real,
      'fat': _real,
    },
    required: {'id', 'week_id', 'date'},
    references: {'week_id': 'fitness_weeks'},
  ),
  'weight_entries': _TableSpec(
    sinceVersion: 1,
    columns: {'id': _text, 'week_id': _text, 'date': _date, 'weight': _real},
    required: {'id', 'week_id', 'date', 'weight'},
    references: {'week_id': 'fitness_weeks'},
  ),
  'weekly_assessments': _TableSpec(
    sinceVersion: 1,
    columns: {
      'id': _text,
      'week_id': _text,
      'sleep_committed': _int,
      'calories_committed': _int,
      'progress': _text,
      'fatigue': _text,
      'fluids_committed': _int,
      'steps_committed': _int,
    },
    required: {'id', 'week_id'},
    references: {'week_id': 'fitness_weeks'},
  ),
  'body_measurements': _TableSpec(
    sinceVersion: 1,
    columns: {
      'id': _text,
      'week_id': _text,
      'chest': _real,
      'calves': _real,
      'waist': _real,
      'glutes': _real,
      'arm': _real,
      'thigh': _real,
      'front_photo_path': _textNullable,
      'back_photo_path': _textNullable,
    },
    required: {'id', 'week_id'},
    references: {'week_id': 'fitness_weeks'},
  ),
  'macro_targets': _TableSpec(
    sinceVersion: 2,
    columns: {
      'id': _int,
      'calories': _real,
      'protein': _real,
      'carbs': _real,
      'fat': _real,
    },
    required: {'id'},
  ),
  'water_goal': _TableSpec(
    sinceVersion: 3,
    columns: {'id': _int, 'daily_goal_ml': _int},
    required: {'id'},
  ),
  'water_entries': _TableSpec(
    sinceVersion: 3,
    columns: {
      'id': _text,
      'date': _date,
      'amount_ml': _int,
      'created_at': _date,
    },
    required: {'id', 'date', 'amount_ml', 'created_at'},
  ),
  'step_entries': _TableSpec(
    sinceVersion: 4,
    columns: {'id': _text, 'week_id': _text, 'date': _date, 'steps': _int},
    required: {'id', 'week_id', 'date'},
    references: {'week_id': 'fitness_weeks'},
  ),
  'step_goal': _TableSpec(
    sinceVersion: 5,
    columns: {'id': _int, 'daily_goal': _int},
    required: {'id'},
  ),
  'user_profile': _TableSpec(
    sinceVersion: 6,
    columns: {
      'id': _int,
      'name': _textNullable,
      'gender': _textNullable,
      'age': _intNullable,
      'height_cm': _realNullable,
      'weight_kg': _realNullable,
      'onboarding_seen': _int,
    },
    required: {'id'},
  ),
};

/// Tables included in a backup, in insertion (parent-before-child) order.
final List<String> backupTables = List.unmodifiable(_specs.keys);

/// Single-row tables (`id = 1`) that the app expects to always exist.
const Set<String> singletonTables = {
  'macro_targets',
  'water_goal',
  'step_goal',
  'user_profile',
};

/// Default rows for [singletonTables], matching the schema defaults.
const Map<String, Map<String, Object?>> singletonDefaults = {
  'macro_targets': {
    'id': 1,
    'calories': 0.0,
    'protein': 0.0,
    'carbs': 0.0,
    'fat': 0.0,
  },
  'water_goal': {'id': 1, 'daily_goal_ml': 2500},
  'step_goal': {'id': 1, 'daily_goal': 10000},
  'user_profile': {'id': 1, 'onboarding_seen': 0},
};

class ParsedBackup {
  final int version;

  /// Validated rows keyed by table. Tables absent from an older backup are
  /// absent here too.
  final Map<String, List<Map<String, Object?>>> tables;

  const ParsedBackup({required this.version, required this.tables});
}

/// Decodes and validates a backup. Throws [BackupFormatException] on any
/// problem; never returns partially-valid data.
ParsedBackup parseBackup(String jsonStr, {required int currentVersion}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(jsonStr);
  } on FormatException catch (e) {
    throw BackupFormatException('Invalid JSON: ${e.message}');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const BackupFormatException('Backup root must be a JSON object');
  }

  final version = decoded['version'];
  if (version is! int || version < 1) {
    throw const BackupFormatException('Missing or invalid backup version');
  }
  if (version > currentVersion) {
    throw BackupFormatException(
      'Backup version $version is newer than supported ($currentVersion)',
    );
  }

  final tables = <String, List<Map<String, Object?>>>{};
  for (final entry in _specs.entries) {
    final table = entry.key;
    final spec = entry.value;
    final raw = decoded[table];
    if (raw == null) {
      if (!decoded.containsKey(table) && version < spec.sinceVersion) continue;
      throw BackupFormatException('Missing table "$table"');
    }
    if (raw is! List) {
      throw BackupFormatException('Table "$table" must be a list');
    }
    tables[table] = [
      for (var i = 0; i < raw.length; i++) _parseRow(table, spec, i, raw[i]),
    ];
  }

  _checkSingletons(tables);
  _checkPrimaryKeys(tables);
  _checkReferences(tables);

  return ParsedBackup(version: version, tables: tables);
}

Map<String, Object?> _parseRow(
  String table,
  _TableSpec spec,
  int index,
  Object? raw,
) {
  final where = '$table[$index]';
  if (raw is! Map) {
    throw BackupFormatException('Row $where in "$table" must be an object');
  }

  final row = <String, Object?>{};
  for (final MapEntry(:key, :value) in raw.entries) {
    final col = spec.columns[key];
    if (key is! String || col == null) {
      throw BackupFormatException('Unknown column "$key" in $where');
    }
    row[key] = _coerce(where, key, col, value);
  }
  for (final name in spec.required) {
    if (!row.containsKey(name)) {
      throw BackupFormatException('Missing column "$name" in $where');
    }
  }
  return row;
}

Object? _coerce(String where, String name, _Col col, Object? value) {
  if (value == null) {
    if (col.nullable) return null;
    throw BackupFormatException('Column "$name" in $where cannot be null');
  }
  switch (col.type) {
    case _ColType.text:
      if (value is! String) break;
      if (col.isDate && DateTime.tryParse(value) == null) {
        throw BackupFormatException(
          'Invalid date "$value" for "$name" in $where',
        );
      }
      return value;
    case _ColType.integer:
      if (value is int) return value;
      if (value is double && value.isFinite && value == value.truncate()) {
        return value.toInt();
      }
      break;
    case _ColType.real:
      if (value is num && value.isFinite) return value.toDouble();
      break;
  }
  throw BackupFormatException(
    'Column "$name" in $where has invalid value ${jsonEncode(value)}',
  );
}

void _checkSingletons(Map<String, List<Map<String, Object?>>> tables) {
  for (final table in singletonTables) {
    final rows = tables[table];
    if (rows == null) continue;
    if (rows.length > 1) {
      throw BackupFormatException('Table "$table" must have at most one row');
    }
    if (rows.isNotEmpty && rows.first['id'] != 1) {
      throw BackupFormatException('Table "$table" row must have id 1');
    }
  }
}

void _checkPrimaryKeys(Map<String, List<Map<String, Object?>>> tables) {
  for (final MapEntry(key: table, value: rows) in tables.entries) {
    final seen = <Object?>{};
    for (final row in rows) {
      if (!seen.add(row['id'])) {
        throw BackupFormatException(
          'Table "$table" has duplicate id "${row['id']}"',
        );
      }
    }
  }
}

void _checkReferences(Map<String, List<Map<String, Object?>>> tables) {
  for (final MapEntry(key: table, value: rows) in tables.entries) {
    for (final MapEntry(key: column, value: parent)
        in _specs[table]!.references.entries) {
      final parentIds = {for (final r in tables[parent] ?? const []) r['id']};
      for (final row in rows) {
        if (!parentIds.contains(row[column])) {
          throw BackupFormatException(
            'Table "$table" references missing $parent "${row[column]}"',
          );
        }
      }
    }
  }
}
