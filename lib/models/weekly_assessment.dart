class WeeklyAssessment {
  final String id;
  final String weekId;
  final bool sleepCommitted;
  final bool caloriesCommitted;
  final String progress; // no_progress, slight, normal, historic
  final String fatigue; // low, medium, high
  final bool fluidsCommitted;
  final bool stepsCommitted;

  WeeklyAssessment({
    required this.id,
    required this.weekId,
    required this.sleepCommitted,
    required this.caloriesCommitted,
    required this.progress,
    required this.fatigue,
    required this.fluidsCommitted,
    required this.stepsCommitted,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week_id': weekId,
      'sleep_committed': sleepCommitted ? 1 : 0,
      'calories_committed': caloriesCommitted ? 1 : 0,
      'progress': progress,
      'fatigue': fatigue,
      'fluids_committed': fluidsCommitted ? 1 : 0,
      'steps_committed': stepsCommitted ? 1 : 0,
    };
  }

  factory WeeklyAssessment.fromMap(Map<String, dynamic> map) {
    return WeeklyAssessment(
      id: map['id'] as String,
      weekId: map['week_id'] as String,
      sleepCommitted: (map['sleep_committed'] as int) == 1,
      caloriesCommitted: (map['calories_committed'] as int) == 1,
      progress: map['progress'] as String,
      fatigue: map['fatigue'] as String,
      fluidsCommitted: (map['fluids_committed'] as int) == 1,
      stepsCommitted: (map['steps_committed'] as int) == 1,
    );
  }

  WeeklyAssessment copyWith({
    bool? sleepCommitted,
    bool? caloriesCommitted,
    String? progress,
    String? fatigue,
    bool? fluidsCommitted,
    bool? stepsCommitted,
  }) {
    return WeeklyAssessment(
      id: id,
      weekId: weekId,
      sleepCommitted: sleepCommitted ?? this.sleepCommitted,
      caloriesCommitted: caloriesCommitted ?? this.caloriesCommitted,
      progress: progress ?? this.progress,
      fatigue: fatigue ?? this.fatigue,
      fluidsCommitted: fluidsCommitted ?? this.fluidsCommitted,
      stepsCommitted: stepsCommitted ?? this.stepsCommitted,
    );
  }
}
