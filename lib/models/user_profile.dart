enum Gender { male, female }

class UserProfile {
  final String? name;
  final Gender? gender;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final bool onboardingSeen;

  UserProfile({
    this.name,
    this.gender,
    this.age,
    this.heightCm,
    this.weightKg,
    this.onboardingSeen = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'name': name,
      'gender': gender?.name,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'onboarding_seen': onboardingSeen ? 1 : 0,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final genderStr = map['gender'] as String?;
    return UserProfile(
      name: map['name'] as String?,
      gender: genderStr == 'male'
          ? Gender.male
          : genderStr == 'female'
              ? Gender.female
              : null,
      age: map['age'] as int?,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      onboardingSeen: (map['onboarding_seen'] as int?) == 1,
    );
  }

  UserProfile copyWith({
    String? name,
    Gender? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    bool? onboardingSeen,
  }) {
    return UserProfile(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    );
  }

  bool get isEmpty =>
      name == null && gender == null && age == null && heightCm == null && weightKg == null;
}
