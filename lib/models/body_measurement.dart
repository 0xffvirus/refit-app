class BodyMeasurement {
  final String id;
  final String weekId;
  final double chest;
  final double calves;
  final double waist;
  final double glutes;
  final double arm;
  final double thigh;
  final String? frontPhotoPath;
  final String? backPhotoPath;

  BodyMeasurement({
    required this.id,
    required this.weekId,
    required this.chest,
    required this.calves,
    required this.waist,
    required this.glutes,
    required this.arm,
    required this.thigh,
    this.frontPhotoPath,
    this.backPhotoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week_id': weekId,
      'chest': chest,
      'calves': calves,
      'waist': waist,
      'glutes': glutes,
      'arm': arm,
      'thigh': thigh,
      'front_photo_path': frontPhotoPath,
      'back_photo_path': backPhotoPath,
    };
  }

  factory BodyMeasurement.fromMap(Map<String, dynamic> map) {
    return BodyMeasurement(
      id: map['id'] as String,
      weekId: map['week_id'] as String,
      chest: (map['chest'] as num).toDouble(),
      calves: (map['calves'] as num).toDouble(),
      waist: (map['waist'] as num).toDouble(),
      glutes: (map['glutes'] as num).toDouble(),
      arm: (map['arm'] as num).toDouble(),
      thigh: (map['thigh'] as num).toDouble(),
      frontPhotoPath: map['front_photo_path'] as String?,
      backPhotoPath: map['back_photo_path'] as String?,
    );
  }

  BodyMeasurement copyWith({
    double? chest,
    double? calves,
    double? waist,
    double? glutes,
    double? arm,
    double? thigh,
    String? frontPhotoPath,
    String? backPhotoPath,
  }) {
    return BodyMeasurement(
      id: id,
      weekId: weekId,
      chest: chest ?? this.chest,
      calves: calves ?? this.calves,
      waist: waist ?? this.waist,
      glutes: glutes ?? this.glutes,
      arm: arm ?? this.arm,
      thigh: thigh ?? this.thigh,
      frontPhotoPath: frontPhotoPath ?? this.frontPhotoPath,
      backPhotoPath: backPhotoPath ?? this.backPhotoPath,
    );
  }
}
