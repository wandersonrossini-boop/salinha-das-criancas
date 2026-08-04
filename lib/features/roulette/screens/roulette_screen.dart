import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
import '../../../core/components/image_helper.dart';
import '../../students/models/student.dart';
import '../../students/screens/chamada_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen> {
  final StreamController<int> _selected = StreamController<int>.broadcast();
  int _lastSelectedIndex = -1;
  
  List<dynamic> _items = []; // Can be Student or String (for Teams)
  List<dynamic> _removedFromRound = [];
  List<String> _history = [];
  bool _isLoading = true;
  String _currentMode = 'Alunos';
  bool _useAllStudents = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _selected.close();
    super.dispose();
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Roleta de Sorteios', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
        content: const Text(
          '1. Por padrão, a roleta filtra apenas os alunos presentes hoje.\n'
          '2. Você pode ativar "Todos os alunos" nas opções.\n'
          '3. Gire a roleta para sortear um aluno ou equipe para participar!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi!'),
          )
        ],
      )
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    if (_currentMode == 'Alunos') {
      final allStudents = await DatabaseHelper.instance.fetchAllStudents();
      List<Student> filtered = [];
      
      if (_useAllStudents) {
        filtered = List<Student>.from(allStudents);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final presentIds = prefs.getStringList('present_student_ids') ?? [];
        filtered = allStudents.where((s) => presentIds.contains(s.id.toString())).toList();
      }

      // Filter out students removed from the current round
      filtered = filtered.where((s) => !_removedFromRound.contains(s.id)).toList();
      
      // Desambiguação de nomes: se houver alunos com o mesmo primeiro nome, adicionar inicial do sobrenome
      List<Student> desambiguated = [];
      for (var s in filtered) {
        final firstName = s.name.trim().split(' ').first;
        final hasDuplicate = filtered.any((o) => o.id != s.id && o.name.trim().split(' ').first.toLowerCase() == firstName.toLowerCase());
        
        if (hasDuplicate) {
          final parts = s.name.trim().split(' ');
          String newName = s.name;
          if (parts.length > 1) {
            final lastInitial = parts.last.isNotEmpty ? parts.last[0] : '';
            newName = '$firstName $lastInitial.';
          }
          desambiguated.add(Student(
            id: s.id,
            name: newName,
            age: s.age,
            avatarPath: s.avatarPath,
            alertMessage: s.alertMessage,
            points: s.points,
            photoUrl: s.photoUrl,
            turma: s.turma,
            teamId: s.teamId,
            birthDate: s.birthDate,
          ));
        } else {
          desambiguated.add(s);
        }
      }
      
      setState(() {
        _items = desambiguated;
      });
    } else {
      final teams = await DatabaseHelper.instance.fetchAllTeams();
      setState(() {
        _items = teams.map((t) => t.name).toList();
      });
    }

    setState(() => _isLoading = false);
  }

  void _spin() {
    if (_items.isNotEmpty) {
      final randomIndex = Random().nextInt(_items.length);
      _lastSelectedIndex = randomIndex;
      _selected.add(randomIndex);
    }
  }

  void _showWinnerPopup() {
    if (_lastSelectedIndex >= 0 && _lastSelectedIndex < _items.length) {
      final winnerObj = _items[_lastSelectedIndex];
      final winnerName = winnerObj is String ? winnerObj : winnerObj.name;
      final winnerPhoto = winnerObj is Student ? winnerObj.photoUrl : null;
      
      setState(() {
        if (!_history.contains(winnerName)) {
          _history.insert(0, winnerName);
          if (_history.length > 5) {
            _history.removeLast();
          }
        }
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sorteado',
                    style: TextStyle(fontFamily: 'Fredoka', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.azulCeleste),
                  ),
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: (winnerPhoto != null && winnerPhoto.isNotEmpty)
                        ? NetworkImage(ImageHelper.getProxiedImageUrl(winnerPhoto)) as ImageProvider
                        : null,
                    child: (winnerPhoto == null || winnerPhoto.isEmpty)
                        ? const Icon(Icons.person, size: 48, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    winnerName,
                    style: const TextStyle(fontFamily: 'Fredoka', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulCeleste,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Manter na roleta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      if (winnerObj is Student) ...[
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _removedFromRound.add(winnerObj.id);
                            });
                            Navigator.pop(context);
                            _loadData();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Remover desta rodada', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _spin();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Girar novamente', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Roleta de Sorteios',
          style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ) : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.azulCeleste),
            onPressed: _showHelp,
            tooltip: 'Regras',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune_rounded),
            onSelected: (value) {
              setState(() {
                _currentMode = value;
                _removedFromRound.clear();
              });
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Alunos', child: Text('Sortear Alunos')),
              const PopupMenuItem(value: 'Equipes', child: Text('Sortear Equipes')),
            ],
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Modo: $_currentMode',
                        style: const TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      if (_currentMode == 'Alunos')
                        Row(
                          children: [
                            const Text('Todos os alunos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Switch(
                              value: _useAllStudents,
                              onChanged: (val) {
                                setState(() {
                                  _useAllStudents = val;
                                });
                                _loadData();
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.stars_rounded, size: 64, color: AppColors.amareloSol),
                                const SizedBox(height: 16),
                                const Text(
                                  'Sorteio Concluído!',
                                  style: TextStyle(fontFamily: 'Fredoka', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Todos os alunos já foram sorteados nesta rodada.',
                                  style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF64748B)),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() => _removedFromRound.clear());
                                    _loadData();
                                  },
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('🔄 Reiniciar Rodada', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.azulCeleste,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _items.length == 1
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                margin: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.amber.shade300, width: 2),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('👑', style: TextStyle(fontSize: 48)),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Último Aluno na Roleta!',
                                      style: TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _items.first is String ? _items.first : (_items.first as Student).name,
                                      style: const TextStyle(fontFamily: 'Fredoka', fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() => _removedFromRound.clear());
                                        _loadData();
                                      },
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('🔄 Reiniciar Rodada', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.azulCeleste,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: FortuneWheel(
                                selected: _selected.stream,
                                animateFirst: false,
                                indicators: [
                                  FortuneIndicator(
                                    alignment: Alignment.topCenter,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Transform.translate(
                                          offset: const Offset(0, 3),
                                          child: const TriangleIndicator(
                                            color: Colors.black26,
                                          ),
                                        ),
                                        const TriangleIndicator(
                                          color: Color(0xFFEF4444),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                items: [
                                  for (var item in _items)
                                    FortuneItem(
                                      child: RotatedBox(
                                        quarterTurns: 0,
                                        child: Text(
                                          item is String ? item : item.name.split(' ').first,
                                          style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                        ),
                                      ),
                                      style: FortuneItemStyle(
                                        color: _getColorForItem(item is String ? item : item.name),
                                        borderColor: Colors.white,
                                        borderWidth: 2,
                                      ),
                                    ),
                                ],
                                onAnimationEnd: () {
                                  _showWinnerPopup();
                                },
                              ),
                            ),
                ),
                if (_history.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Últimos Sorteados:', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: _history.map((h) => Chip(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade200),
                            label: Text(h, style: const TextStyle(fontSize: 11, fontFamily: 'Fredoka')),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 12, 24, 24),
                  child: ElevatedButton(
                    onPressed: _items.length <= 1
                        ? () {
                            setState(() => _removedFromRound.clear());
                            _loadData();
                          }
                        : _spin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulCeleste,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      _items.length <= 1 ? '🔄 REINICIAR RODADA' : 'GIRAR A ROLETA',
                      style: const TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Color _getColorForItem(String item) {
    final colors = [
      AppColors.azulCeleste,
      AppColors.amareloSol,
      AppColors.verdePasto,
      AppColors.laranjaCriativo,
      AppColors.roxoAcolhedor,
    ];
    return colors[item.hashCode.abs() % colors.length];
  }
}
