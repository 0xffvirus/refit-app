class FitnessWeek {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  FitnessWeek({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_date': _dateOnly(startDate),
      'end_date': _dateOnly(endDate),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FitnessWeek.fromMap(Map<String, dynamic> map) {
    return FitnessWeek(
      id: map['id'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static String _dateOnly(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
