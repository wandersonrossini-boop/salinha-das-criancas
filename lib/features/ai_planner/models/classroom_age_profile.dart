import '../../../core/utils/safe_converters.dart';

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
      minAge: safeInt(map['minAge'], fallback: 4),
      maxAge: safeInt(map['maxAge'], fallback: 11),
      isMixedAge: safeBool(map['isMixedAge'], fallback: false),
      activeBands: safeStringList(map['activeBands']),
    );
  }
}
