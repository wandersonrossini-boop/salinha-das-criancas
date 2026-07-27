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
    return Student(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      avatarPath: map['avatarPath'],
      alertMessage: map['alertMessage'],
      points: map['points'] ?? 0,
      photoUrl: map['photoUrl'],
      turma: map['turma'],
      teamId: map['teamId'],
      birthDate: map['birthDate'],
    );
  }
}
