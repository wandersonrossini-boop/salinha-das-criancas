import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/student.dart';
import '../../../core/db/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChamadaScreen extends StatefulWidget {
  const ChamadaScreen({super.key});

  @override
  State<ChamadaScreen> createState() => _ChamadaScreenState();
}

class _ChamadaScreenState extends State<ChamadaScreen> {
  List<Student> _students = [];
  bool _isLoading = true;
  // Mapeia o id do estudante para o status de presença (true = presente, false = ausente)
  Map<int, bool> _presence = {};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final students = await DatabaseHelper.instance.fetchAllStudents();
    setState(() {
      _students = students;
      _isLoading = false;
      for (var student in students) {
        // Inicializa todos como ausentes (cinza)
        _presence[student.id!] = false;
      }
    });
  }

  void _togglePresence(int studentId) {
    setState(() {
      _presence[studentId] = !(_presence[studentId] ?? false);
    });
  }

  void _showStudentModal([Student? student]) {
    final nameController = TextEditingController(text: student?.name ?? '');
    final ageController = TextEditingController(text: student?.age.toString() ?? '');
    final alertController = TextEditingController(text: student?.alertMessage ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(student == null ? 'Novo Aluno' : 'Editar Aluno'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(labelText: 'Idade'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: alertController,
                  decoration: const InputDecoration(labelText: 'Alerta (Alergias, etc)'),
                ),
              ],
            ),
          ),
          actions: [
            if (student != null)
              TextButton(
                onPressed: () async {
                  await DatabaseHelper.instance.deleteStudent(student.id!);
                  if (context.mounted) Navigator.pop(context);
                  _loadStudents();
                },
                child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final age = int.tryParse(ageController.text.trim()) ?? 0;
                final alert = alertController.text.trim();

                if (name.isNotEmpty) {
                  final newStudent = Student(
                    id: student?.id,
                    name: name,
                    age: age,
                    alertMessage: alert.isEmpty ? null : alert,
                    points: student?.points ?? 0,
                  );

                  if (student == null) {
                    await DatabaseHelper.instance.insertStudent(newStudent);
                  } else {
                    await DatabaseHelper.instance.updateStudent(newStudent);
                  }
                  
                  if (context.mounted) Navigator.pop(context);
                  _loadStudents();
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chamada Rápida', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showStudentModal(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? _buildEmptyState()
              : _buildGrid(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final presentIds = _presence.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key.toString())
              .toList();
          await prefs.setStringList('present_student_ids', presentIds);

          // Save to Database History
          final date = DateTime.now().toIso8601String().split('T')[0];
          final presentIntIds = _presence.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .toList();
          await DatabaseHelper.instance.insertAttendance(date, presentIntIds);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chamada salva com sucesso!')),
            );
            Navigator.pop(context);
          }
        },
        backgroundColor: AppColors.azulCeleste,
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text('Salvar Chamada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'Nenhum aluno cadastrado ainda.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 avatares por linha
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
        childAspectRatio: 0.8,
      ),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final isPresent = _presence[student.id] ?? false;

        return GestureDetector(
          onTap: () => _togglePresence(student.id!),
          onLongPress: () => _showStudentModal(student),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: isPresent ? AppColors.presente : AppColors.ausente,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      backgroundImage: student.photoUrl != null && student.photoUrl!.isNotEmpty
                          ? NetworkImage(student.photoUrl!) as ImageProvider
                          : student.avatarPath != null
                              ? AssetImage(student.avatarPath!) as ImageProvider
                              : null,
                      child: (student.photoUrl == null || student.photoUrl!.isEmpty) && student.avatarPath == null
                          ? Text(
                              student.name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isPresent ? AppColors.presente : AppColors.ausente,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (student.alertMessage != null && student.alertMessage!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.alerta,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                student.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
