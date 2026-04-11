class StepEntry {
  final String id;
  final String weekId;
  final DateTime date;
  final int steps;

  StepEntry({
    required this.id,
    required this.weekId,
    required this.date,
    required this.steps,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week_id': weekId,
      'date': _dateOnly(date),
      'steps': steps,
    };
  }

  factory StepEntry.fromMap(Map<String, dynamic> map) {
    return StepEntry(
      id: map['id'] as String,
      weekId: map['week_id'] as String,
      date: DateTime.parse(map['date'] as String),
      steps: (map['steps'] as num).toInt(),
    );
  }

  StepEntry copyWith({int? steps}) {
    return StepEntry(
      id: id,
      weekId: weekId,
      date: date,
      steps: steps ?? this.steps,
    );
  }

  static String _dateOnly(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
