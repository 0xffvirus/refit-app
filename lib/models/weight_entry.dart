class WeightEntry {
  final String id;
  final String weekId;
  final DateTime date;
  final double weight;

  WeightEntry({
    required this.id,
    required this.weekId,
    required this.date,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week_id': weekId,
      'date': _dateOnly(date),
      'weight': weight,
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as String,
      weekId: map['week_id'] as String,
      date: DateTime.parse(map['date'] as String),
      weight: (map['weight'] as num).toDouble(),
    );
  }

  WeightEntry copyWith({double? weight}) {
    return WeightEntry(
      id: id,
      weekId: weekId,
      date: date,
      weight: weight ?? this.weight,
    );
  }

  static String _dateOnly(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
