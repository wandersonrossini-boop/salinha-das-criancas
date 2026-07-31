import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/student.dart';
import '../../../core/db/database_helper.dart';
import '../../../core/components/image_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChamadaScreen extends StatefulWidget {
  const ChamadaScreen({super.key});

  @override
  State<ChamadaScreen> createState() => _ChamadaScreenState();
}

class _ChamadaScreenState extends State<ChamadaScreen> {
  List<Student> _students = [];
  bool _isLoading = true;
  bool _hasChanges = false;
  
  // Mapeia o id do estudante para o status de presença:
  // 0 = Não marcado (cinza/branco)
  // 1 = Presente (verde)
  // 2 = Ausente (vermelho)
  // 3 = Visitante (azul)
  Map<int, int> _presenceState = {};

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
        _presenceState[student.id!] = 0;
      }
    });
  }

  void _cyclePresence(int studentId) {
    setState(() {
      _hasChanges = true;
      final current = _presenceState[studentId] ?? 0;
      _presenceState[studentId] = (current + 1) % 4;
    });
  }

  void _showStudentModal([Student? student]) {
    final nameController = TextEditingController(text: student?.name ?? '');
    final ageController = TextEditingController(text: student?.age.toString() ?? '');
    final alertController = TextEditingController(text: student?.alertMessage ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    student == null ? '👶 Novo Aluno' : '✏️ Editar Aluno',
                    style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Nome do Aluno',
                      labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 14),
                      hintText: 'Digite o nome completo',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.azulCeleste, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ageController,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 15),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Idade',
                      labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 14),
                      hintText: 'Ex: 6',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.azulCeleste, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: alertController,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 15),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Observações',
                      labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 14),
                      hintText: 'Alergias, restrições ou informações importantes.',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.azulCeleste, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (student != null)
                        TextButton(
                          onPressed: () async {
                            await DatabaseHelper.instance.deleteStudent(student.id!);
                            if (context.mounted) Navigator.pop(context);
                            _loadStudents();
                          },
                          child: const Text('Excluir', style: TextStyle(fontFamily: 'Fredoka', color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar', style: TextStyle(fontFamily: 'Fredoka', color: Color(0xFF64748B))),
                      ),
                      const SizedBox(width: 8),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulCeleste,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Salvar', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int total = _students.length;
    int presentes = _presenceState.values.where((v) => v == 1 || v == 3).length;
    int ausentes = _presenceState.values.where((v) => v == 2).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chamada Rápida',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
            ),
            Text(
              '$total alunos • $presentes presentes • $ausentes ausentes',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: () => _showStudentModal(),
              icon: const Icon(Icons.person_add_rounded, size: 16, color: AppColors.azulCeleste),
              label: const Text('Aluno', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(child: _buildGrid()),
                    _buildBottomBar(presentes),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🐑', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Nenhum aluno cadastrado ainda',
              style: TextStyle(fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cadastre seus pequenos para começar a marcar presença na salinha.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showStudentModal(),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Adicionar Aluno', style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulCeleste,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 5 : (constraints.maxWidth > 500 ? 4 : 3);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _students.length,
          itemBuilder: (context, index) {
            final student = _students[index];
            final state = _presenceState[student.id] ?? 0;

            Color cardBg = Colors.white;
            Color borderCol = Colors.grey.shade200;
            Color textCol = const Color(0xFF1E293B);
            Widget? statusWidget;

            if (state == 1) {
              cardBg = const Color(0xFFECFDF5);
              borderCol = const Color(0xFF10B981);
              textCol = const Color(0xFF065F46);
              statusWidget = const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18);
            } else if (state == 2) {
              cardBg = const Color(0xFFFEF2F2);
              borderCol = const Color(0xFFEF4444);
              textCol = const Color(0xFF991B1B);
              statusWidget = const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 18);
            } else if (state == 3) {
              cardBg = const Color(0xFFEFF6FF);
              borderCol = const Color(0xFF3B82F6);
              textCol = const Color(0xFF1E40AF);
              statusWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(6)),
                child: const Text('Vis', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'Fredoka')),
              );
            }

            return GestureDetector(
              onTap: () => _cyclePresence(student.id!),
              onLongPress: () => _showStudentModal(student),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(state > 0 ? 0.04 : 0.01), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.transparent,
                          backgroundImage: student.photoUrl != null && student.photoUrl!.isNotEmpty
                              ? NetworkImage(ImageHelper.getProxiedImageUrl(student.photoUrl)) as ImageProvider
                              : const AssetImage('assets/images/mascot/poses/idle.png') as ImageProvider,
                        ),
                        if (student.alertMessage != null && student.alertMessage!.isNotEmpty)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2.0),
                              decoration: const BoxDecoration(
                                color: AppColors.alerta,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 10),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      student.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: textCol,
                      ),
                    ),
                    if (statusWidget != null) ...[
                      const SizedBox(height: 4),
                      statusWidget,
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar(int presentes) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2))]
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _hasChanges ? () async {
            final prefs = await SharedPreferences.getInstance();
            final presentIds = _presenceState.entries
                .where((entry) => entry.value == 1 || entry.value == 3)
                .map((entry) => entry.key.toString())
                .toList();
            await prefs.setStringList('present_student_ids', presentIds);
            final todayDate = DateTime.now().toIso8601String().split('T')[0];
            await prefs.setString('attendance_date', todayDate);

            final date = todayDate;
            final presentIntIds = _presenceState.entries
                .where((entry) => entry.value == 1 || entry.value == 3)
                .map((entry) => entry.key)
                .toList();
            await DatabaseHelper.instance.insertAttendance(date, presentIntIds);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chamada salva com sucesso! 🎉')),
              );
              Navigator.pop(context);
            }
          } : null,
          icon: const Icon(Icons.check, size: 16),
          label: Text(
            _hasChanges ? 'Salvar Lista ($presentes Presentes)' : 'Nenhuma alteração',
            style: const TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.verdePasto,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade200,
            disabledForegroundColor: Colors.grey.shade400,
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
