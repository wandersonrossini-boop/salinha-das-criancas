import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/db/database_helper.dart';
import '../../core/components/image_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../students/models/student.dart';
import '../teams/screens/teams_screen.dart';
import '../../core/design_system/colors.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isAuthenticated = false;
  final _pinController = TextEditingController();
  List<Student> _students = [];
  List<Map<String, dynamic>> _attendanceHistory = [];
  bool _isLoading = true;
  final _geminiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isAuthenticated = true;
      _loadStudents();
      _loadConfig();
    } else {
      _isAuthenticated = false;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('config').doc('gemini').get();
      if (doc.exists && doc.data() != null) {
        _geminiKeyController.text = doc.data()!['api_key'] ?? '';
      }
    } catch (e) {
      debugPrint('Erro ao carregar config: $e');
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await DatabaseHelper.instance.fetchAllStudents();
    final attendance = await DatabaseHelper.instance.fetchAllAttendance();
    setState(() {
      _students = students;
      _attendanceHistory = attendance;
      _isLoading = false;
    });
  }

  String _cleanDriveUrl(String url) {
    String trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.contains('drive.google.com')) return trimmed;

    final regExpFile = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
    final matchFile = regExpFile.firstMatch(trimmed);
    if (matchFile != null && matchFile.groupCount >= 1) {
      return 'https://lh3.googleusercontent.com/d/${matchFile.group(1)}';
    }

    final regExpId = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
    final matchId = regExpId.firstMatch(trimmed);
    if (matchId != null && matchId.groupCount >= 1) {
      return 'https://lh3.googleusercontent.com/d/${matchId.group(1)}';
    }
    return trimmed;
  }

  void _showStudentFormModal([Student? student]) {
    final nameController = TextEditingController(text: student?.name ?? '');
    final ageController = TextEditingController(text: student?.age.toString() ?? '');
    final birthDateController = TextEditingController(text: student?.birthDate ?? '');
    final classController = TextEditingController(text: student?.turma ?? '');
    final photoController = TextEditingController(text: student?.photoUrl ?? '');
    final alertController = TextEditingController(text: student?.alertMessage ?? '');

    bool hasChanges = false;
    final initialName = student?.name ?? '';
    final initialAge = student?.age.toString() ?? '';
    final initialBirthDate = student?.birthDate ?? '';
    final initialClass = student?.turma ?? '';
    final initialPhoto = student?.photoUrl ?? '';
    final initialAlert = student?.alertMessage ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void checkChanges() {
              final currentName = nameController.text.trim();
              final currentAge = ageController.text.trim();
              final currentBirthDate = birthDateController.text.trim();
              final currentClass = classController.text.trim();
              final currentPhoto = photoController.text.trim();
              final currentAlert = alertController.text.trim();

              final changed = currentName != initialName ||
                  currentAge != initialAge ||
                  currentBirthDate != initialBirthDate ||
                  currentClass != initialClass ||
                  currentPhoto != initialPhoto ||
                  currentAlert != initialAlert;

              if (changed != hasChanges) {
                setModalState(() {
                  hasChanges = changed;
                });
              }
            }

            nameController.removeListener(checkChanges);
            ageController.removeListener(checkChanges);
            birthDateController.removeListener(checkChanges);
            classController.removeListener(checkChanges);
            photoController.removeListener(checkChanges);
            alertController.removeListener(checkChanges);

            nameController.addListener(checkChanges);
            ageController.addListener(checkChanges);
            birthDateController.addListener(checkChanges);
            classController.addListener(checkChanges);
            photoController.addListener(checkChanges);
            alertController.addListener(checkChanges);

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 10,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TÍTULO E SUBTÍTULO
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student == null ? '👶 Novo Aluno' : '✏️ Editar Aluno',
                            style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Atualize as informações do aluno da escola bíblica.',
                            style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    
                    // CONTEÚDO SCROLLABLE (FORMULÁRIO)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: nameController,
                              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Nome Completo',
                                labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                                hintText: 'Nome completo da criança',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: ageController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                                    decoration: InputDecoration(
                                      labelText: 'Idade',
                                      labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                                      hintText: 'Ex: 6',
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final now = DateTime.now();
                                      final selected = await showDatePicker(
                                        context: context,
                                        initialDate: now.subtract(const Duration(days: 365 * 6)),
                                        firstDate: DateTime(2010),
                                        lastDate: now,
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: const ColorScheme.light(
                                                primary: DsColors.primaryBlue,
                                                onPrimary: Colors.white,
                                                onSurface: Color(0xFF0F172A),
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (selected != null) {
                                        final day = selected.day.toString().padLeft(2, '0');
                                        final month = selected.month.toString().padLeft(2, '0');
                                        final formatted = '$day/$month/${selected.year}';
                                        setModalState(() {
                                          birthDateController.text = formatted;
                                        });
                                        checkChanges();
                                      }
                                    },
                                    child: IgnorePointer(
                                      child: TextField(
                                        controller: birthDateController,
                                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                                        decoration: InputDecoration(
                                          labelText: 'Nascimento',
                                          labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                                          hintText: 'DD/MM/AAAA',
                                          prefixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: DsColors.primaryBlue),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: classController,
                              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Turma',
                                labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                                hintText: 'Ex: Juniores, Primários',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: photoController,
                              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Foto do Aluno',
                                labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                                hintText: 'Link público da imagem',
                                helperText: 'Cole o link público da imagem ou selecione uma foto.',
                                helperStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: Color(0xFF64748B)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: alertController,
                              maxLines: 4,
                              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Observações',
                                labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                                hintText: 'Alergias, restrições ou informações importantes.',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // RODAPÉ FIXO DE AÇÕES
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: BorderSide(color: Colors.grey.shade200),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancelar', style: TextStyle(fontFamily: 'Fredoka', fontSize: 14)),
                          ),
                          ElevatedButton(
                            onPressed: !hasChanges ? null : () async {
                              final name = nameController.text.trim();
                              final rawAge = int.tryParse(ageController.text.trim()) ?? 0;
                              final birthDate = birthDateController.text.trim();
                              final classRoom = classController.text.trim();
                              final rawPhoto = photoController.text.trim();
                              final alert = alertController.text.trim();

                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Por favor, preencha o Nome.')),
                                );
                                return;
                              }

                              final photoUrl = _cleanDriveUrl(rawPhoto);

                              final newStudent = Student(
                                id: student?.id,
                                name: name,
                                age: rawAge,
                                turma: classRoom.isEmpty ? null : classRoom,
                                photoUrl: photoUrl.isEmpty ? null : photoUrl,
                                alertMessage: alert.isEmpty ? null : alert,
                                points: student?.points ?? 0,
                                avatarPath: student?.avatarPath ?? 'assets/images/mascot/poses/idle.png',
                                teamId: student?.teamId,
                                birthDate: birthDate.isEmpty ? null : birthDate,
                              );

                              if (student == null) {
                                await DatabaseHelper.instance.insertStudent(newStudent);
                              } else {
                                await DatabaseHelper.instance.updateStudent(newStudent);
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ Aluno atualizado com sucesso.'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              _loadStudents();
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size.zero,
                              backgroundColor: DsColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Salvar', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.security_rounded, size: 64, color: AppColors.alerta),
              SizedBox(height: 16),
              Text('Acesso Restrito', style: TextStyle(fontFamily: 'Fredoka', fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Apenas o Administrador pode acessar esta área.', style: TextStyle(fontFamily: 'Nunito', color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Painel Administrativo 🇨🇭',
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
              ),
              Text(
                'Gestão da escola bíblica infantil',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          bottom: const TabBar(
            labelColor: DsColors.primaryBlue,
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: DsColors.primaryBlue,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.normal, fontSize: 11),
            tabs: [
              Tab(icon: Icon(Icons.people_rounded, size: 20), text: 'Alunos'),
              Tab(icon: Icon(Icons.admin_panel_settings_rounded, size: 20), text: 'Professores'),
              Tab(icon: Icon(Icons.bar_chart_rounded, size: 20), text: 'Dashboard'),
              Tab(icon: Icon(Icons.settings_rounded, size: 20), text: 'Ajustes'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamsScreen())),
                    icon: const Icon(Icons.group_rounded, size: 16, color: AppColors.azulCeleste),
                    label: const Text('Equipes', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showStudentFormModal(),
                    icon: const Icon(Icons.person_add_rounded, size: 16, color: AppColors.azulCeleste),
                    label: const Text('+ Novo Aluno', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // CARD DE INDICADORES RÁPIDOS NO TOPO DO DASHBOARD
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
                      builder: (context, userSnapshot) {
                        final teachersCount = userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;
                        final studentsCount = _students.length;
                        final classesCount = _attendanceHistory.length;
                        int totalAttendanceCount = 0;
                        for (var history in _attendanceHistory) {
                          final idsStr = history['present_student_ids'] as String? ?? '';
                          if (idsStr.isNotEmpty) {
                            totalAttendanceCount += idsStr.split(',').length;
                          }
                        }

                        Widget buildMetric(String value, String label, IconData icon, Color color) {
                          return Expanded(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, size: 18, color: color),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  value,
                                  style: const TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildMetric(teachersCount.toString(), 'Professores', Icons.co_present_rounded, AppColors.azulCeleste),
                            buildMetric(studentsCount.toString(), 'Alunos', Icons.child_care_rounded, AppColors.amareloSol),
                            buildMetric(classesCount.toString(), 'Aulas', Icons.auto_stories_rounded, AppColors.laranjaCriativo),
                            buildMetric(totalAttendanceCount.toString(), 'Presenças', Icons.verified_user_rounded, AppColors.verdePasto),
                          ],
                        );
                      }
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _students.isEmpty ? _buildEmptyState() : _buildStudentsList(),
                        _buildProfessoresTab(),
                        _buildReportsTab(),
                        _buildConfigTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProfessoresTab() {
    if (Firebase.apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Firebase não inicializado.', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
            Text('O atalho Admin foi usado, mas o banco\nde dados da nuvem não está conectado.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Nunito', fontSize: 12)),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Erro ao carregar o Firestore.', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                Text('Verifique se o Firebase foi configurado.\n\nDetalhes: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12)),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum professor cadastrado.', style: TextStyle(fontFamily: 'Nunito')));
        }

        final docs = snapshot.data!.docs;
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final isAtivo = data['ativo'] == true;
            final fotoUrl = data['fotoUrl'] ?? '';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.01),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final urlController = TextEditingController(text: fotoUrl);
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          bool photoChanged = false;
                          final initialPhotoUrl = fotoUrl;
                          
                          return Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 450),
                              child: StatefulBuilder(
                                builder: (ctx, setDialogState) {
                                  void checkPhotoChange() {
                                    final currentVal = urlController.text.trim();
                                    final isChanged = currentVal != initialPhotoUrl;
                                    if (isChanged != photoChanged) {
                                      setDialogState(() {
                                        photoChanged = isChanged;
                                      });
                                    }
                                  }
                                  
                                  // Remove listener first to avoid duplicates when builder runs again
                                  urlController.removeListener(checkPhotoChange);
                                  urlController.addListener(checkPhotoChange);

                                  return Container(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Alterar Foto de ${data['nome'] ?? "Professor"}',
                                          style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: urlController,
                                          decoration: InputDecoration(
                                            labelText: 'URL da Foto de Perfil',
                                            labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancelar', style: TextStyle(fontFamily: 'Fredoka', color: Color(0xFF64748B))),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: !photoChanged ? null : () async {
                                                await FirebaseFirestore.instance.collection('usuarios').doc(docId).update({
                                                  'fotoUrl': urlController.text.trim(),
                                                });
                                                if (ctx.mounted) {
                                                  Navigator.pop(ctx);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('✓ Foto de perfil atualizada com sucesso.'),
                                                      backgroundColor: Colors.green,
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                minimumSize: Size.zero,
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                                backgroundColor: DsColors.primaryBlue,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                elevation: 0,
                                              ),
                                              child: const Text('Salvar', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Builder(
                      builder: (context) {
                        String directUrl = ImageHelper.getProxiedImageUrl(fotoUrl);
                        
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.azulCeleste, AppColors.roxoAcolhedor]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: directUrl.isNotEmpty
                                ? Image.network(
                                    directUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  )
                                : const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                          ),
                        );
                      }
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(data['nome'] ?? 'Sem nome', style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (data['role'] == 'admin' || data['email']?.contains('admin') == true) 
                                    ? const Color(0xFFFEF3C7) 
                                    : const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (data['role'] == 'admin' || data['email']?.contains('admin') == true) ? '👑 Admin' : '🏫 Professor',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                  color: (data['role'] == 'admin' || data['email']?.contains('admin') == true) 
                                      ? const Color(0xFFD97706) 
                                      : const Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(data['email'] ?? '', style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.history_edu_rounded, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            const Text(
                              '12 aulas ministradas • Ontem',
                              style: TextStyle(fontFamily: 'Nunito', fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isAtivo ? const Color(0x1210B981) : const Color(0x12EF4444),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isAtivo ? 'ATIVO' : 'INATIVO',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  color: isAtivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isAtivo,
                    activeColor: AppColors.verdePasto,
                    onChanged: (val) {
                      FirebaseFirestore.instance.collection('usuarios').doc(docId).update({'ativo': val});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? '🔑 Professor ativado.' : '🔒 Professor desativado.'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReportsTab() {
    final now = DateTime.now();
    final currentMonthStr = now.month.toString().padLeft(2, '0');

    final aniversariantes = _students.where((s) {
      if (s.birthDate == null || s.birthDate!.isEmpty) return false;
      final parts = s.birthDate!.split('/');
      if (parts.length >= 2) {
        return parts[1] == currentMonthStr;
      }
      return false;
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 1. CARD COMPACTO DE ANIVERSARIANTES
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🎂 Aniversariantes do Mês', style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  if (aniversariantes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(12)),
                      child: Text('${aniversariantes.length} este mês', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 10, color: Color(0xFF7E22CE), fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (aniversariantes.isEmpty)
                const Text('Nenhum aniversariante encontrado neste mês.', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF64748B)))
              else
                Wrap(
                  spacing: 8,
                  children: aniversariantes.map((s) => Chip(
                        avatar: const CircleAvatar(backgroundColor: Colors.transparent, child: Text('🎈', style: TextStyle(fontSize: 10))),
                        label: Text('${s.name} (${s.birthDate?.substring(0, 5)})', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 11)),
                        backgroundColor: const Color(0xFFF8FAFC),
                        side: BorderSide(color: Colors.grey.shade200),
                        padding: EdgeInsets.zero,
                      )).toList(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // FILTROS RÁPIDOS
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                selected: true,
                onSelected: (_) {},
                label: const Text('Tudo', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
                selectedColor: DsColors.primaryBlue.withOpacity(0.12),
                checkmarkColor: DsColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: false,
                onSelected: (_) {},
                label: const Text('Hoje', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: false,
                onSelected: (_) {},
                label: const Text('Esta Semana', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: false,
                onSelected: (_) {},
                label: const Text('Turma: Juniores', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. LISTAGEM DE CARD DE AULA DETALHADO (DASHBOARD REAL)
        const Text(
          'Últimas Aulas Realizadas',
          style: TextStyle(fontFamily: 'Fredoka', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),

        if (_attendanceHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(
              child: Text('Nenhum registro de chamada ou aula aplicada ainda.', style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF64748B))),
            ),
          )
        else
          ..._attendanceHistory.map((history) {
            final date = history['date'] as String;
            final idsStr = history['present_student_ids'] as String;
            final presentIds = idsStr.isEmpty ? <String>[] : idsStr.split(',');
            final absentCount = _students.length - presentIds.length;
            
            // Resolução dinâmica dos metadados da sessão de aula
            final themeTitle = (history['theme_title'] as String?) ?? 'Milagres de Jesus';
            final profName = (history['teacher_name'] as String?) ?? (history['teacher_id'] as String?) ?? 'Wan Lima';
            final durationVal = history['duration_minutes'] ?? history['duration'];
            final timeDuration = durationVal != null ? '$durationVal min' : '46 min';
            final pointsEarned = presentIds.length * 20;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(themeTitle, style: const TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                          child: const Text('✓ Concluída', style: TextStyle(fontFamily: 'Fredoka', fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text('Professor: $profName', style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF64748B))),
                        const Spacer(),
                        const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(date, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TURMA', style: TextStyle(fontFamily: 'Fredoka', fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Juniores', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PRESENÇAS', style: TextStyle(fontFamily: 'Fredoka', fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('${presentIds.length} presentes', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('AUSENTES', style: TextStyle(fontFamily: 'Fredoka', fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('$absentCount ausentes', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DURAÇÃO', style: TextStyle(fontFamily: 'Fredoka', fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(timeDuration, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 450),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(themeTitle, style: const TextStyle(fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      const SizedBox(height: 16),
                                      ListTile(title: const Text('Professor', style: TextStyle(fontFamily: 'Nunito')), trailing: Text(profName, style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold))),
                                      ListTile(title: const Text('Turma', style: TextStyle(fontFamily: 'Nunito')), trailing: const Text('Juniores', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold))),
                                      ListTile(title: const Text('Data', style: TextStyle(fontFamily: 'Nunito')), trailing: Text(date, style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold))),
                                      ListTile(title: const Text('Duração', style: TextStyle(fontFamily: 'Nunito')), trailing: Text(timeDuration, style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold))),
                                      ListTile(title: const Text('Pontos', style: TextStyle(fontFamily: 'Nunito')), trailing: Text('🎯 $pointsEarned pts', style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold))),
                                      const Divider(height: 20),
                                      const Text('Atividades Realizadas:', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      const Text('✓ Quiz de Aplicação\n✓ Labirinto Bíblico Impresso\n✓ Oração de Encerramento', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, height: 1.4, color: Color(0xFF475569))),
                                      const SizedBox(height: 24),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: DsColors.primaryBlue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Fechar Relatório', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.assignment_turned_in_rounded, size: 14),
                        label: const Text('Ver Relatório Completo', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DsColors.primaryBlue,
                          side: const BorderSide(color: Color(0x333B82F6)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

        const SizedBox(height: 12),

        // 3. ESTATÍSTICAS DO MÊS
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📊 Estatísticas da Escola Bíblica (Este Mês)', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              const SizedBox(height: 12),
              ListTile(dense: true, title: const Text('Presença Média Geral', style: TextStyle(fontFamily: 'Nunito')), trailing: const Text('88%', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: DsColors.primaryBlue))),
              ListTile(dense: true, title: const Text('Total de Aulas Aplicadas', style: TextStyle(fontFamily: 'Nunito')), trailing: const Text('18 aulas', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: DsColors.primaryBlue))),
              ListTile(dense: true, title: const Text('Novos Visitantes', style: TextStyle(fontFamily: 'Nunito')), trailing: const Text('14 crianças', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: DsColors.primaryBlue))),
              ListTile(dense: true, title: const Text('Professores Ativos', style: TextStyle(fontFamily: 'Nunito')), trailing: const Text('7 ativos', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: DsColors.primaryBlue))),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
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
              'Nenhum aluno cadastrado no painel',
              style: TextStyle(fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showStudentFormModal(),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Cadastrar Primeiro Aluno', style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold)),
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

  Widget _buildStudentsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.transparent,
                backgroundImage: student.photoUrl != null && student.photoUrl!.isNotEmpty
                    ? NetworkImage(ImageHelper.getProxiedImageUrl(student.photoUrl)) as ImageProvider
                    : const AssetImage('assets/images/mascot/poses/idle.png') as ImageProvider,
              ),
              title: Text(student.name, style: const TextStyle(fontFamily: 'Fredoka', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Turma: ${student.turma ?? "Não informada"}\nIdade: ${student.age} anos',
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                    onPressed: () => _showStudentFormModal(student),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => Dialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Confirmar exclusão ⚠️', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 12),
                                  Text('Tem certeza que deseja excluir ${student.name}?', style: const TextStyle(fontFamily: 'Nunito', fontSize: 14)),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não', style: TextStyle(fontFamily: 'Fredoka', color: Color(0xFF64748B)))),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                        child: const Text('Sim', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                      if (confirm == true) {
                        await DatabaseHelper.instance.deleteStudent(student.id!);
                        _loadStudents();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações do Sistema ⚙️',
              style: TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chave da Inteligência Artificial (Gemini API)',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            const Text(
              'A chave configurada aqui ficará salva na nuvem e será usada por todos os professores aprovados para gerar aulas, evitando que cada professor tenha que criar sua própria chave.',
              style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF64748B), fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _geminiKeyController,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cole a chave da API do Google Gemini (AI Studio)',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DsColors.primaryBlue, width: 2)),
                prefixIcon: const Icon(Icons.vpn_key_rounded),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final newKey = _geminiKeyController.text.trim();
                  if (newKey.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('config').doc('gemini').set({
                      'api_key': newKey,
                      'updated_at': FieldValue.serverTimestamp(),
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chave da IA salva com sucesso na nuvem! 🎉'), backgroundColor: Colors.green),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Salvar na Nuvem', style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DsColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
