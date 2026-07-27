import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/db/database_helper.dart';
import '../../core/components/image_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../students/models/student.dart';
import '../teams/screens/teams_screen.dart';

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
      // É o admin que logou com senha fixa
      _isAuthenticated = true;
      _loadStudents();
      _loadConfig();
    } else {
      // É um professor (Firebase Auth)
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

    // Matches /file/d/[ID]/view
    final regExpFile = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
    final matchFile = regExpFile.firstMatch(trimmed);
    if (matchFile != null && matchFile.groupCount >= 1) {
      return 'https://lh3.googleusercontent.com/d/${matchFile.group(1)}';
    }

    // Matches ?id=[ID] or &id=[ID]
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(student == null ? 'Cadastrar Novo Aluno' : 'Editar Aluno', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome Completo'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Idade (opcional se der data de nasc.)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: birthDateController,
                  decoration: const InputDecoration(labelText: 'Data de Nascimento (DD/MM/AAAA)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: classController,
                  decoration: const InputDecoration(labelText: 'Turma (ex: Juniores)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: photoController,
                  decoration: const InputDecoration(
                    labelText: 'URL da Foto (Google Drive)',
                    hintText: 'Cole o link de compartilhamento',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: alertController,
                  decoration: const InputDecoration(labelText: 'Observação / Alergia (opcional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
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
                  avatarPath: student?.avatarPath,
                  teamId: student?.teamId,
                  birthDate: birthDate.isEmpty ? null : birthDate,
                );

                if (student == null) {
                  await DatabaseHelper.instance.insertStudent(newStudent);
                } else {
                  await DatabaseHelper.instance.updateStudent(newStudent);
                }

                if (context.mounted) Navigator.pop(context);
                _loadStudents();
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
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.security_rounded, size: 64, color: AppColors.alerta),
              SizedBox(height: 16),
              Text('Acesso Restrito', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Apenas o Administrador pode acessar esta área.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Painel Administrativo', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.background,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppColors.azulCeleste,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.azulCeleste,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Gestão de Alunos'),
              Tab(icon: Icon(Icons.admin_panel_settings), text: 'Professores'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Relatórios & Frequência'),
              Tab(icon: Icon(Icons.settings), text: 'Configurações'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.group, color: AppColors.textPrimary),
              tooltip: 'Gerenciar Equipes',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamsScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.person_add, color: AppColors.textPrimary),
              tooltip: 'Adicionar Aluno',
              onPressed: () => _showStudentFormModal(),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _students.isEmpty ? _buildEmptyState() : _buildStudentsList(),
                  _buildProfessoresTab(),
                  _buildReportsTab(),
                  _buildConfigTab(),
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
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Firebase não inicializado.', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('O atalho Admin foi usado, mas o banco\nde dados da nuvem não está conectado.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
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
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Erro ao carregar o Firestore.', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Verifique se o Firebase foi configurado.\n\nDetalhes: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum professor cadastrado.'));
        }

        final docs = snapshot.data!.docs;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final isAtivo = data['ativo'] == true;
            final fotoUrl = data['fotoUrl'] ?? '';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.08),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.02),
                    blurRadius: 8,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
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
                        builder: (ctx) => AlertDialog(
                          title: Text('Alterar Foto de ${data['nome'] ?? "Professor"}'),
                          content: TextField(
                            controller: urlController,
                            decoration: const InputDecoration(
                              labelText: 'URL da Foto de Perfil',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('usuarios').doc(docId).update({
                                  'fotoUrl': urlController.text.trim(),
                                });
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              child: const Text('Salvar'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Builder(
                      builder: (context) {
                        String directUrl = ImageHelper.getProxiedImageUrl(fotoUrl);
                        
                        return Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.azulCeleste, AppColors.roxoAcolhedor]),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: directUrl.isNotEmpty
                                ? Image.network(
                                    directUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  )
                                : const Icon(Icons.person, color: Colors.white, size: 32),
                          ),
                        );
                      }
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(data['email'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAtivo ? const Color(0x1A00D294) : const Color(0x1AFF5252),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isAtivo ? 'ATIVO' : 'INATIVO',
                            style: TextStyle(
                              color: isAtivo ? Colors.green[800] : Colors.red[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isAtivo,
                    activeColor: AppColors.verdePasto,
                    onChanged: (val) {
                      FirebaseFirestore.instance.collection('usuarios').doc(docId).update({'ativo': val});
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
    final currentMonthStr = now.month.toString().padLeft(2, '0'); // '07'

    final aniversariantes = _students.where((s) {
      if (s.birthDate == null || s.birthDate!.isEmpty) return false;
      final parts = s.birthDate!.split('/');
      if (parts.length >= 2) {
        return parts[1] == currentMonthStr;
      }
      return false;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Aniversariantes do Mês', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        if (aniversariantes.isEmpty)
          const Text('Nenhum aniversariante encontrado neste mês.', style: TextStyle(color: AppColors.textSecondary))
        else
          ...aniversariantes.map((s) => Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.cake, color: AppColors.roxoAcolhedor),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Data: ${s.birthDate}'),
                ),
              )).toList(),

        const Divider(height: 48),
        
        const Text('Histórico de Frequência', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        if (_attendanceHistory.isEmpty)
          const Text('Nenhum histórico de chamada salvo ainda.', style: TextStyle(color: AppColors.textSecondary))
        else
          ..._attendanceHistory.map((history) {
            final date = history['date'] as String;
            final idsStr = history['present_student_ids'] as String;
            final presentIds = idsStr.isEmpty ? <String>[] : idsStr.split(',');
            
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text('Data: $date', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${presentIds.length} aluno(s) presente(s)'),
                leading: const Icon(Icons.event_available, color: AppColors.verdePasto),
                children: presentIds.map((idStr) {
                  final s = _students.firstWhere((st) => st.id.toString() == idStr, orElse: () => Student(name: 'Aluno Desconhecido (ID: $idStr)', age: 0));
                  return ListTile(
                    title: Text(s.name),
                    leading: const Icon(Icons.person_outline),
                  );
                }).toList(),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.admin_panel_settings_outlined, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'Nenhum aluno cadastrado no painel.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.azulCeleste.withOpacity(0.2),
              backgroundImage: student.photoUrl != null && student.photoUrl!.isNotEmpty
                  ? NetworkImage(ImageHelper.getProxiedImageUrl(student.photoUrl))
                  : null,
              child: student.photoUrl == null || student.photoUrl!.isEmpty
                  ? Text(student.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.azulCeleste))
                  : null,
              onBackgroundImageError: (exception, stackTrace) {
                // Fallback handled automatically (image won't render, shows child if built or blank)
              },
            ),
            title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Idade: ${student.age} anos | Turma: ${student.turma ?? "Não informada"}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showStudentFormModal(student),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar exclusão'),
                        content: Text('Tem certeza que deseja excluir ${student.name}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sim')),
                        ],
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
        );
      },
    );
  }

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configurações do Sistema',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chave da Inteligência Artificial (Gemini API)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'A chave configurada aqui ficará salva na nuvem e será usada por todos os professores aprovados para gerar aulas, evitando que cada professor tenha que criar sua própria chave.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _geminiKeyController,
            decoration: InputDecoration(
              hintText: 'Cole a chave da API do Google Gemini (AI Studio)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.vpn_key_rounded),
            ),
            obscureText: true, // Ocultar a chave por segurança
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
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
                      const SnackBar(content: Text('Chave da IA salva com sucesso na nuvem!'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Salvar na Nuvem'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
