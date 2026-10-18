import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/students/models/student.dart';
import '../../features/ai_planner/models/lesson_plan.dart';
import '../../features/teams/models/team.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  // Método auxiliar para compatibilidade com códigos legados
  Future<dynamic> get database async => null;

  /// Retorna o contexto do professor/coordenador logado atualmente
  Future<Map<String, dynamic>> getCurrentTeacherContext() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? '';
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String name = prefs.getString('user_name') ?? '';
      if (name.isEmpty) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 4));
          if (doc.exists && doc.data() != null) {
            name = doc.data()!['nome']?.toString() ?? 'Professor';
            await prefs.setString('user_name', name);
          }
        } catch (_) {}
      }
      if (name.isEmpty) name = 'Professor';
      return {
        'id': user.uid,
        'name': name,
        'isCoordinator': role == 'coordenador' || role == 'admin',
      };
    }

    return {
      'id': prefs.getString('user_id') ?? 'admin',
      'name': prefs.getString('user_name') ?? 'Administrador',
      'isCoordinator': true,
    };
  }

  /// Lista todos os professores ativos cadastrados para seleção/filtro
  Future<List<Map<String, String>>> fetchActiveTeachers() async {
    final List<Map<String, String>> list = [
      {'id': 'admin', 'name': 'Administrador (Geral)'},
    ];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('ativo', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 6));
      for (final doc in snap.docs) {
        final data = doc.data();
        final nome = data['nome']?.toString().trim() ?? '';
        if (nome.isNotEmpty) {
          list.add({
            'id': doc.id,
            'name': nome,
          });
        }
      }
    } catch (e) {
      print("Erro ao buscar lista de professores: $e");
    }
    return list;
  }

  Future<void> deleteTeacher(String teacherId, {bool deleteLessons = false}) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(teacherId)
        .delete();

    if (deleteLessons) {
      final snap = await FirebaseFirestore.instance
          .collection('lesson_plans')
          .where('teacherId', isEqualTo: teacherId)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }
  }

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
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('students')
          .get()
          .timeout(const Duration(seconds: 8));
      final List<Student> students = [];
      for (final doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          if (data['id'] == null) {
            data['id'] = int.tryParse(doc.id);
          }
          students.add(Student.fromMap(data));
        } catch (e) {
          print("Documento de aluno ignorado (${doc.id}): $e");
        }
      }
      students.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return students;
    } catch (e) {
      print("Erro ou timeout ao buscar alunos: $e");
      return [];
    }
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
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('teams')
          .orderBy('id', descending: false)
          .get()
          .timeout(const Duration(seconds: 8));
      return snapshot.docs.map((doc) => Team.fromMap(doc.data())).toList();
    } catch (e) {
      print("Erro ou timeout ao buscar equipes: $e");
      return [];
    }
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
  Future<int> insertLessonPlan(LessonPlan plan, {int? customId}) async {
    final ctx = await getCurrentTeacherContext();
    final id = customId ?? plan.id ?? DateTime.now().millisecondsSinceEpoch;
    final enrichedPlan = plan.copyWith(
      id: id,
      teacherId: plan.teacherId.isNotEmpty
          ? plan.teacherId
          : ctx['id']?.toString(),
      teacherName: plan.teacherName.isNotEmpty
          ? plan.teacherName
          : ctx['name']?.toString(),
    );
    final planMap = enrichedPlan.toMap();
    planMap['id'] = id;
    await FirebaseFirestore.instance
        .collection('lesson_plans')
        .doc(id.toString())
        .set(planMap);
    return id;
  }

  String _normalizeLessonTitle(String title) {
    return title
        .replaceFirst(RegExp(r'^aula\s*\d+\s*[-:]\s*', caseSensitive: false), '')
        .trim()
        .toLowerCase();
  }

  Future<List<LessonPlan>> fetchAllLessonPlans({String? filterTeacherId}) async {
    try {
      final ctx = await getCurrentTeacherContext();
      final bool isCoordinator = ctx['isCoordinator'] == true;
      final String currentTeacherId = ctx['id']?.toString() ?? '';

      final snapshot = await FirebaseFirestore.instance
          .collection('lesson_plans')
          .orderBy('id', descending: true)
          .get()
          .timeout(const Duration(seconds: 8));
      final List<LessonPlan> rawPlans = [];
      for (final doc in snapshot.docs) {
        try {
          final plan = LessonPlan.fromMap(doc.data());
          if (!isCoordinator && currentTeacherId.isNotEmpty) {
            // Cada professor vê apenas as suas próprias aulas
            if (plan.teacherId == currentTeacherId) {
              rawPlans.add(plan);
            }
          } else if (filterTeacherId != null && filterTeacherId.isNotEmpty && filterTeacherId != 'all') {
            if (plan.teacherId == filterTeacherId) {
              rawPlans.add(plan);
            }
          } else {
            rawPlans.add(plan);
          }
        } catch (e) {
          print("Documento corrompido ignorado (${doc.id}): $e");
        }
      }

      // 1. Remove aulas duplicadas (mesmo título normalizado para o mesmo professor/série)
      final Set<String> seenKeys = {};
      final List<LessonPlan> uniquePlans = [];
      for (final plan in rawPlans) {
        final normTitle = _normalizeLessonTitle(plan.title);
        final scopeKey = plan.seriesId.isNotEmpty
            ? '${plan.seriesId}_$normTitle'
            : '${plan.teacherId}_$normTitle';
        if (seenKeys.contains(scopeKey)) {
          // Remove duplicata do banco em segundo plano
          if (plan.id != null) {
            FirebaseFirestore.instance
                .collection('lesson_plans')
                .doc(plan.id.toString())
                .delete()
                .catchError((_) {});
          }
          continue;
        }
        seenKeys.add(scopeKey);
        uniquePlans.add(plan);
      }

      // 2. Reorganiza e renumera cada série (Aula 1..N de N) para corrigir contagens quebradas (ex: 5 aulas quando 1 era repetida)
      final Map<String, List<LessonPlan>> seriesMap = {};
      for (final plan in uniquePlans) {
        if (plan.seriesId.isNotEmpty) {
          seriesMap.putIfAbsent(plan.seriesId, () => []).add(plan);
        }
      }

      final Map<int, LessonPlan> normalizedById = {};
      for (final entry in seriesMap.entries) {
        final list = entry.value;
        list.sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
        final int realTotal = list.length;
        for (int i = 0; i < realTotal; i++) {
          final item = list[i];
          final int realNum = i + 1;
          final String cleanSub = item.title
              .replaceFirst(RegExp(r'^aula\s*\d+\s*[-:]\s*', caseSensitive: false), '')
              .trim();
          final String fixedTitle = realTotal > 1 ? 'Aula $realNum - $cleanSub' : item.title;
          final fixedPlan = item.copyWith(
            title: fixedTitle,
            lessonNumber: realNum,
            totalLessonsInSeries: realTotal,
          );
          if (fixedPlan.id != null) {
            normalizedById[fixedPlan.id!] = fixedPlan;
          }
        }
      }

      final List<LessonPlan> plans = uniquePlans.map((p) {
        if (p.id != null && normalizedById.containsKey(p.id)) {
          return normalizedById[p.id!]!;
        }
        return p;
      }).toList();

      // Ordena mantendo as séries mais recentes no topo, mas dentro da mesma série (seriesId)
      // ordena em sequência crescente (Aula 1, Aula 2, Aula 3, Aula 4)
      plans.sort((a, b) {
        if (a.seriesId.isNotEmpty && a.seriesId == b.seriesId) {
          return a.lessonNumber.compareTo(b.lessonNumber);
        }
        final idA = a.id ?? 0;
        final idB = b.id ?? 0;
        return idB.compareTo(idA);
      });

      return plans;
    } catch (e) {
      print("Erro ou timeout ao buscar planos de aula: $e");
      return [];
    }
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

  Future<void> deleteLessonPlan(int id) async {
    await FirebaseFirestore.instance
        .collection('lesson_plans')
        .doc(id.toString())
        .delete();
  }

  Future<void> deleteLessonSeries(String seriesId) async {
    if (seriesId.isEmpty) return;
    final snap = await FirebaseFirestore.instance
        .collection('lesson_plans')
        .where('seriesId', isEqualTo: seriesId)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
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
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('attendance_history')
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 8));
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Erro ou timeout ao buscar histórico de presença: $e");
      return [];
    }
  }
}
