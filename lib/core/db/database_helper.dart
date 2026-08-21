import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/students/models/student.dart';
import '../../features/ai_planner/models/lesson_plan.dart';
import '../../features/teams/models/team.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  // Método auxiliar para compatibilidade com códigos legados
  Future<dynamic> get database async => null;

  // --- Operações de Aluno ---
  Future<int> insertStudent(Student student) async {
    final id = student.id ?? DateTime.now().millisecondsSinceEpoch;
    final newStudent = Student(
      id: id,
      name: student.name,
      age: student.age,
      avatarPath: student.avatarPath,
      alertMessage: student.alertMessage,
      points: student.points,
      photoUrl: student.photoUrl,
      turma: student.turma,
      teamId: student.teamId,
      birthDate: student.birthDate,
    );
    await FirebaseFirestore.instance
        .collection('students')
        .doc(id.toString())
        .set(newStudent.toMap());
    return id;
  }

  Future<List<Student>> fetchAllStudents([String? turmaId]) async {
    Query query = FirebaseFirestore.instance.collection('students');
    if (turmaId != null && turmaId.isNotEmpty) {
      query = query.where('turma', isEqualTo: turmaId);
    }
    final snapshot = await query.orderBy('name', descending: false).get();
    return snapshot.docs.map((doc) => Student.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<int> updateStudent(Student student) async {
    if (student.id == null) return 0;
    await FirebaseFirestore.instance
        .collection('students')
        .doc(student.id.toString())
        .update(student.toMap());
    return student.id!;
  }

  Future<int> deleteStudent(int id) async {
    await FirebaseFirestore.instance
        .collection('students')
        .doc(id.toString())
        .delete();
    return id;
  }

  // --- Operações de Equipe ---
  Future<int> insertTeam(Team team) async {
    final id = team.id ?? DateTime.now().millisecondsSinceEpoch;
    final newTeam = Team(
      id: id,
      name: team.name,
      color: team.color,
      points: team.points,
    );
    await FirebaseFirestore.instance
        .collection('teams')
        .doc(id.toString())
        .set(newTeam.toMap());
    return id;
  }

  Future<List<Team>> fetchAllTeams() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('teams')
        .orderBy('id', descending: false)
        .get();
    return snapshot.docs.map((doc) => Team.fromMap(doc.data())).toList();
  }

  Future<int> updateTeam(Team team) async {
    if (team.id == null) return 0;
    await FirebaseFirestore.instance
        .collection('teams')
        .doc(team.id.toString())
        .update(team.toMap());
    return team.id!;
  }

  Future<int> deleteTeam(int id) async {
    await FirebaseFirestore.instance
        .collection('teams')
        .doc(id.toString())
        .delete();
    return id;
  }

  // --- Operações de Plano de Aula ---
  Future<int> insertLessonPlan(LessonPlan plan) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    final planMap = plan.toMap();
    planMap['id'] = id;
    await FirebaseFirestore.instance
        .collection('lesson_plans')
        .doc(id.toString())
        .set(planMap);
    return id;
  }

  Future<List<LessonPlan>> fetchAllLessonPlans() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('lesson_plans')
        .orderBy('id', descending: true)
        .get();
    return snapshot.docs.map((doc) => LessonPlan.fromMap(doc.data())).toList();
  }

  Future<void> updateLessonPlan(LessonPlan plan) async {
    if (plan.id == null) {
      throw ArgumentError('O ID da lição não pode ser nulo para atualizações.');
    }
    await FirebaseFirestore.instance
        .collection('lesson_plans')
        .doc(plan.id.toString())
        .update(plan.toMap());
  }

  // --- Operações de Histórico de Chamada ---
  Future<int> insertAttendance(String date, List<int> presentIds) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await FirebaseFirestore.instance
        .collection('attendance_history')
        .doc(id.toString())
        .set({
      'id': id,
      'date': date,
      'present_student_ids': presentIds.join(','),
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> fetchAllAttendance() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('attendance_history')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
