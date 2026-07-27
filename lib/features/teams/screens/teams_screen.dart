import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
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

    // Sort descending by age (oldest to youngest)
    presentStudents.sort((a, b) => b.age.compareTo(a.age));

    // Clear previous assignments
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

    // Alternate assignment
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
    // Cor padrão: Azul
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
            return AlertDialog(
              title: Text(team == null ? 'Nova Equipe' : 'Editar Equipe'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nome da Equipe'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Cor da Equipe:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: colorOptions.map((colorVal) {
                        return GestureDetector(
                          onTap: () {
                            setStateModal(() {
                              selectedColor = colorVal;
                            });
                          },
                          child: CircleAvatar(
                            backgroundColor: Color(colorVal),
                            radius: 16,
                            child: selectedColor == colorVal
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                if (team != null)
                  TextButton(
                    onPressed: () async {
                      await DatabaseHelper.instance.deleteTeam(team.id!);
                      if (context.mounted) Navigator.pop(context);
                      _loadTeams();
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
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Equipes e Pontos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textPrimary),
            onPressed: () => _showTeamModal(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? _buildEmptyState()
              : _buildList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sortearEquipesBalanceadas,
        backgroundColor: AppColors.laranjaCriativo,
        icon: const Icon(Icons.shuffle, color: Colors.white),
        label: const Text('Sortear Equipes Balanceadas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            'Nenhuma equipe criada.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teams.length,
      itemBuilder: (context, index) {
        final team = _teams[index];
        final teamColor = Color(team.color);

        return GestureDetector(
          onLongPress: () => _showTeamModal(team),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: teamColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield, color: teamColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.amareloSol, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${team.points} Pontos',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final teamStudents = _allStudents.where((s) => s.teamId == team.id).toList();
                          if (teamStudents.isNotEmpty) {
                            return Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: teamStudents.map((s) {
                                return Chip(
                                  padding: EdgeInsets.zero,
                                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  avatar: CircleAvatar(
                                    backgroundImage: s.photoUrl != null && s.photoUrl!.isNotEmpty
                                        ? NetworkImage(s.photoUrl!)
                                        : null,
                                    child: s.photoUrl == null || s.photoUrl!.isEmpty
                                        ? Text(s.name[0].toUpperCase(), style: const TextStyle(fontSize: 10))
                                        : null,
                                  ),
                                  label: Text('${s.name} (${s.age}a)'),
                                );
                              }).toList(),
                            );
                          } else {
                            return const Text(
                              'Nenhum membro escalado.',
                              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _addPoints(team, -10),
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.alerta),
                    ),
                    IconButton(
                      onPressed: () => _addPoints(team, 10),
                      icon: const Icon(Icons.add_circle, color: AppColors.presente, size: 32),
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
