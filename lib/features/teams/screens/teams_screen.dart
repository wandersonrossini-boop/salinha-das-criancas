import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
import '../../../core/components/image_helper.dart';
import '../models/team.dart';
import '../../students/models/student.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  List<Team> _teams = [];
  List<Student> _allStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    final teams = await DatabaseHelper.instance.fetchAllTeams();
    teams.sort((a, b) => b.points.compareTo(a.points));
    final students = await DatabaseHelper.instance.fetchAllStudents();
    setState(() {
      _teams = teams;
      _allStudents = students;
      _isLoading = false;
    });
  }

  void _addPoints(Team team, int pointsToAdd) async {
    final updatedTeam = Team(
      id: team.id,
      name: team.name,
      color: team.color,
      points: team.points + pointsToAdd,
    );
    await DatabaseHelper.instance.updateTeam(updatedTeam);
    _loadTeams();
  }

  void _sortearEquipesBalanceadas() async {
    if (_teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie pelo menos uma equipe primeiro!')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final presentIdsStr = prefs.getStringList('present_student_ids') ?? [];
    final presentIds = presentIdsStr.map((id) => int.parse(id)).toSet();

    List<Student> presentStudents = _allStudents.where((s) => presentIds.contains(s.id)).toList();

    if (presentStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum aluno marcado como PRESENTE hoje! Faça a chamada primeiro.')),
      );
      return;
    }

    presentStudents.sort((a, b) => b.age.compareTo(a.age));

    for (var s in _allStudents) {
      final clearedStudent = Student(
        id: s.id,
        name: s.name,
        age: s.age,
        avatarPath: s.avatarPath,
        alertMessage: s.alertMessage,
        points: s.points,
        photoUrl: s.photoUrl,
        turma: s.turma,
        teamId: null,
      );
      await DatabaseHelper.instance.updateStudent(clearedStudent);
    }

    for (int i = 0; i < presentStudents.length; i++) {
      final student = presentStudents[i];
      final teamIndex = i % _teams.length;
      final assignedTeam = _teams[teamIndex];

      final updatedStudent = Student(
        id: student.id,
        name: student.name,
        age: student.age,
        avatarPath: student.avatarPath,
        alertMessage: student.alertMessage,
        points: student.points,
        photoUrl: student.photoUrl,
        turma: student.turma,
        teamId: assignedTeam.id,
      );
      await DatabaseHelper.instance.updateStudent(updatedStudent);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Equipes balanceadas por idade sorteadas com sucesso! 🎉')),
    );

    _loadTeams();
  }

  void _showTeamModal([Team? team]) {
    final nameController = TextEditingController(text: team?.name ?? '');
    int selectedColor = team?.color ?? 0xFF2196F3;
    final List<int> colorOptions = [
      0xFF2196F3, // Azul
      0xFFFF5722, // Laranja
      0xFF4CAF50, // Verde
      0xFF9C27B0, // Roxo
      0xFFF44336, // Vermelho
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 10,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        team == null ? '🛡️ Nova Equipe' : '✏️ Editar Equipe',
                        style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Nome da Equipe',
                          labelStyle: const TextStyle(fontFamily: 'Fredoka', fontSize: 14),
                          hintText: 'Digite o nome da equipe',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.azulCeleste, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Cor da Equipe:',
                        style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: colorOptions.map((colorVal) {
                          final isSelected = selectedColor == colorVal;
                          return GestureDetector(
                            onTap: () {
                              setStateModal(() {
                                selectedColor = colorVal;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Color(colorVal),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(color: Color(colorVal).withOpacity(0.4), blurRadius: 8, spreadRadius: 2)
                                  else
                                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 3, offset: const Offset(0, 1))
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (team != null)
                            TextButton(
                              onPressed: () async {
                                await DatabaseHelper.instance.deleteTeam(team.id!);
                                if (context.mounted) Navigator.pop(context);
                                _loadTeams();
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
                              if (name.isNotEmpty) {
                                final newTeam = Team(
                                  id: team?.id,
                                  name: name,
                                  color: selectedColor,
                                  points: team?.points ?? 0,
                                );

                                if (team == null) {
                                  await DatabaseHelper.instance.insertTeam(newTeam);
                                } else {
                                  await DatabaseHelper.instance.updateTeam(newTeam);
                                }
                                
                                if (context.mounted) Navigator.pop(context);
                                _loadTeams();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size.zero,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Equipes e Pontos',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
            ),
            Text(
              'Gerencie pontuações e membros das equipes',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ) : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: () => _showTeamModal(),
              icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.azulCeleste),
              label: const Text('Equipe', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
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
          : _teams.isEmpty
              ? _buildEmptyState()
              : _buildList(),
      bottomNavigationBar: _isLoading || _teams.isEmpty ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            onPressed: _sortearEquipesBalanceadas,
            icon: const Icon(Icons.shuffle_rounded, size: 18),
            label: const Text('Sortear Equipes Balanceadas', style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.laranjaCriativo,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0.5,
            ),
          ),
        ),
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
            const Text('🛡️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma equipe criada',
              style: TextStyle(fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crie equipes para começar a distribuir pontos durante as dinâmicas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showTeamModal(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar Equipe', style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold)),
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

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _teams.length,
      itemBuilder: (context, index) {
        final team = _teams[index];
        final teamColor = Color(team.color);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Container(
            // Identidade da equipe na borda esquerda do Card
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border(left: BorderSide(color: teamColor, width: 6)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: teamColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_rounded, color: teamColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.amareloSol, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${team.points} Pontos',
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Builder(
                          builder: (context) {
                            final teamStudents = _allStudents.where((s) => s.teamId == team.id).toList();
                            if (teamStudents.isNotEmpty) {
                              return Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: teamStudents.map((s) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade100),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundImage: s.photoUrl != null && s.photoUrl!.isNotEmpty
                                              ? NetworkImage(ImageHelper.getProxiedImageUrl(s.photoUrl))
                                              : null,
                                          child: s.photoUrl == null || s.photoUrl!.isEmpty
                                              ? Text(s.name[0].toUpperCase(), style: const TextStyle(fontSize: 8, fontFamily: 'Fredoka', fontWeight: FontWeight.bold))
                                              : null,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          s.name,
                                          style: const TextStyle(fontFamily: 'Fredoka', fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${s.age}a',
                                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            } else {
                              return const Text(
                                'Nenhum membro escalado.',
                                style: TextStyle(fontFamily: 'Nunito', fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Painel de Ações Agrupadas
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => _showTeamModal(team),
                        icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF64748B), size: 24),
                        tooltip: 'Editar / Excluir Equipe',
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _addPoints(team, -10),
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.alerta, size: 22),
                          ),
                          IconButton(
                            onPressed: () => _addPoints(team, 10),
                            icon: const Icon(Icons.add_circle_rounded, color: AppColors.verdePasto, size: 30),
                          ),
                        ],
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
}
