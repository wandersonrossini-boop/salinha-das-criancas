import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
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
  bool _isLoading = true;
  String _currentMode = 'Alunos'; // 'Alunos' ou 'Equipes'

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
        title: const Text('📖 Regras - Roleta'),
        content: const Text(
          '1. A roleta filtra automaticamente os alunos marcados como PRESENTES na chamada.\n'
          '2. Gire a roleta para sortear quem responderá à pergunta ou fará a leitura.'
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
      final prefs = await SharedPreferences.getInstance();
      final presentIds = prefs.getStringList('present_student_ids') ?? [];
      final allStudents = await DatabaseHelper.instance.fetchAllStudents();
      
      final presentStudents = allStudents.where((s) => presentIds.contains(s.id.toString())).toList();
      
      setState(() {
        _items = presentStudents;
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
    if (_items.isNotEmpty && _items.first != 'Nenhum presente' && _items.first != 'Adicione equipes') {
      final randomIndex = Random().nextInt(_items.length);
      _lastSelectedIndex = randomIndex;
      _selected.add(randomIndex);
    }
  }

  void _showWinnerPopup() {
    if (_lastSelectedIndex >= 0 && _lastSelectedIndex < _items.length) {
      final winnerObj = _items[_lastSelectedIndex];
      final winnerName = winnerObj is String ? winnerObj : winnerObj.name;
      
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Temos um ganhador! 🎉', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (winnerObj is! String && winnerObj.photoUrl != null && winnerObj.photoUrl!.isNotEmpty)
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(winnerObj.photoUrl!) as ImageProvider,
                  ),
                const SizedBox(height: 16),
                Text(
                  winnerName,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.presente),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulCeleste,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Eba!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Roleta de Sorteios', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.azulCeleste),
            onPressed: _showHelp,
            tooltip: 'Regras',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune),
            onSelected: (value) {
              setState(() {
                _currentMode = value;
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
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Modo: $_currentMode',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.amber),
                              const SizedBox(height: 12),
                              Text(
                                _currentMode == 'Alunos' 
                                    ? 'Nenhum aluno encontrado ou presente!' 
                                    : 'Nenhuma equipe cadastrada!',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _currentMode == 'Alunos' 
                                    ? 'Faça a chamada para habilitar o sorteio.' 
                                    : 'Crie equipes para habilitar o sorteio.',
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: FortuneWheel(
                            selected: _selected.stream,
                            animateFirst: false,
                            items: [
                              for (var item in _items)
                                FortuneItem(
                                  child: _buildItemChild(item),
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
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ElevatedButton(
                    onPressed: _items.isEmpty ? null : _spin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulCeleste,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 64),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('GIRAR A ROLETA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildItemChild(dynamic item) {
    if (item is String) {
      return Text(item, style: const TextStyle(fontWeight: FontWeight.bold));
    } else {
      // It's a Student
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.photoUrl != null && item.photoUrl!.isNotEmpty) ...[
            CircleAvatar(
              radius: 12,
              backgroundImage: NetworkImage(item.photoUrl!) as ImageProvider,
            ),
            const SizedBox(width: 8),
          ],
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      );
    }
  }

  Color _getColorForItem(String item) {
    // Alternar cores dinamicamente baseado na string para a roleta ficar colorida
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
