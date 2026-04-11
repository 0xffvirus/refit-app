class HabitEntry {
  final String id;
  final String habitId;
  final DateTime date;
  final bool completed;

  HabitEntry({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': _dateOnly(date),
      'completed': completed ? 1 : 0,
    };
  }

  factory HabitEntry.fromMap(Map<String, dynamic> map) {
    return HabitEntry(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      date: DateTime.parse(map['date'] as String),
      completed: (map['completed'] as int) == 1,
    );
  }

  HabitEntry copyWith({bool? completed}) {
    return HabitEntry(
      id: id,
      habitId: habitId,
      date: date,
      completed: completed ?? this.completed,
    );
  }

  static String _dateOnly(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
