/// Body measurements the risk estimate is based on. Kept on this device only.
class UserProfile {
  final int age;
  final bool female;
  final double heightCm;
  final double weightKg;
  final double waistCm;

  const UserProfile({
    required this.age,
    required this.female,
    required this.heightCm,
    required this.weightKg,
    required this.waistCm,
  });

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));
  double get waistToHeight => waistCm / heightCm;

  Map<String, dynamic> toJson() => {
    'age': age,
    'female': female,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'waistCm': waistCm,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    age: (json['age'] as num).toInt(),
    female: json['female'] as bool,
    heightCm: (json['heightCm'] as num).toDouble(),
    weightKg: (json['weightKg'] as num).toDouble(),
    waistCm: (json['waistCm'] as num).toDouble(),
  );
}
