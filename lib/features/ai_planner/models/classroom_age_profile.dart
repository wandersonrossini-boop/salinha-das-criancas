class ClassroomAgeProfile {
  final int minAge;
  final int maxAge;
  final bool isMixedAge;
  final List<String> activeBands;

  ClassroomAgeProfile({
    required this.minAge,
    required this.maxAge,
    required this.isMixedAge,
    required this.activeBands,
  });

  Map<String, dynamic> toMap() {
    return {
      'minAge': minAge,
      'maxAge': maxAge,
      'isMixedAge': isMixedAge,
      'activeBands': activeBands,
    };
  }

  factory ClassroomAgeProfile.fromMap(Map<String, dynamic> map) {
    return ClassroomAgeProfile(
      minAge: map['minAge'] ?? 4,
      maxAge: map['maxAge'] ?? 11,
      isMixedAge: map['isMixedAge'] ?? false,
      activeBands: List<String>.from(map['activeBands'] ?? []),
    );
  }
}
