class NutritionEntry {
  final String id;
  final String weekId;
  final DateTime date;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  NutritionEntry({
    required this.id,
    required this.weekId,
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week_id': weekId,
      'date': _dateOnly(date),
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  factory NutritionEntry.fromMap(Map<String, dynamic> map) {
    return NutritionEntry(
      id: map['id'] as String,
      weekId: map['week_id'] as String,
      date: DateTime.parse(map['date'] as String),
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
    );
  }

  NutritionEntry copyWith({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    return NutritionEntry(
      id: id,
      weekId: weekId,
      date: date,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }

  static String _dateOnly(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
