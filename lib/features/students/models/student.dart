class Student {
  final int? id;
  final String name;
  final int age;
  final String? avatarPath;
  final String? alertMessage; // Para alergias, restrições de busca
  final int points;
  final String? photoUrl; // Link da foto (Google Drive ou web)
  final String? turma;    // Turma do aluno
  final int? teamId;      // ID da equipe associada
  final String? birthDate;// Data de nascimento (DD/MM/AAAA)

  Student({
    this.id,
    required this.name,
    required this.age,
    this.avatarPath,
    this.alertMessage,
    this.points = 0,
    this.photoUrl,
    this.turma,
    this.teamId,
    this.birthDate,
  });

  /// Classifica automaticamente a criança pela faixa etária oficial (4–7 ou 8–11 anos).
  static String classifyAgeGroup(int age) {
    if (age >= 4 && age <= 7) {
      return '4–7 anos';
    } else if (age >= 8 && age <= 11) {
      return '8–11 anos';
    }
    return '$age anos';
  }

  String get ageGroupLabel => classifyAgeGroup(age);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'avatarPath': avatarPath,
      'alertMessage': alertMessage,
      'points': points,
      'photoUrl': photoUrl,
      'turma': turma,
      'teamId': teamId,
      'birthDate': birthDate,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    int? parseId(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString());
    }

    int parseInt(dynamic val, [int fallback = 0]) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    return Student(
      id: parseId(map['id']),
      name: (map['name'] ?? 'Aluno').toString(),
      age: parseInt(map['age'], 6),
      avatarPath: map['avatarPath']?.toString(),
      alertMessage: map['alertMessage']?.toString(),
      points: parseInt(map['points'], 0),
      photoUrl: map['photoUrl']?.toString(),
      turma: map['turma']?.toString(),
      teamId: parseId(map['teamId']),
      birthDate: map['birthDate']?.toString(),
    );
  }
}
