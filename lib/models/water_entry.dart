class WaterEntry {
  final String id;
  final DateTime date;
  final int amountMl;
  final DateTime createdAt;

  WaterEntry({
    required this.id,
    required this.date,
    required this.amountMl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': _dateOnly(date),
      'amount_ml': amountMl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WaterEntry.fromMap(Map<String, dynamic> map) {
    return WaterEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      amountMl: map['amount_ml'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static String _dateOnly(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
