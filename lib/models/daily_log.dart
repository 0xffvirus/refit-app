class DailyLog {
  final String id;
  final DateTime date;
  final int mood;
  final double sleepHours;

  DailyLog({
    required this.id,
    required this.date,
    required this.mood,
    required this.sleepHours,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': _dateOnly(date),
      'mood': mood,
      'sleep_hours': sleepHours,
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      mood: map['mood'] as int,
      sleepHours: (map['sleep_hours'] as num).toDouble(),
    );
  }

  DailyLog copyWith({int? mood, double? sleepHours}) {
    return DailyLog(
      id: id,
      date: date,
      mood: mood ?? this.mood,
      sleepHours: sleepHours ?? this.sleepHours,
    );
  }

  static String _dateOnly(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
