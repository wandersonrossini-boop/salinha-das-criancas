import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<List<Student>> fetchAllStudents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('students')
        .orderBy('name', descending: false)
        .get();
    return snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList();
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

  Future<LessonPlan?> fetchLessonOfTheWeek() async {
    final plans = await fetchAllLessonPlans();
    return plans.isNotEmpty ? plans.first : null;
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

  Future<void> markLessonAsCompleted(int? lessonId) async {
    if (lessonId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lesson_completed_$lessonId', true);
    try {
      await FirebaseFirestore.instance
          .collection('lesson_plans')
          .doc(lessonId.toString())
          .update({'status': 'concluída', 'completed': true});
    } catch (_) {}
  }
}
