class Team {
  final int? id;
  final String name;
  final int color; // int representação de Color
  final int points;

  Team({
    this.id,
    required this.name,
    required this.color,
    this.points = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'points': points,
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      points: map['points'],
    );
  }
}
