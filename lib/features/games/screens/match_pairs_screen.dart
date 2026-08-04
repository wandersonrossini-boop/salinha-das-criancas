import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
import '../../../core/services/audio_service.dart';

class MatchPair {
  final String id;
  final String leftTitle;
  final String leftEmoji;
  final String rightTitle;
  final String rightEmoji;

  MatchPair({
    required this.id,
    required this.leftTitle,
    required this.leftEmoji,
    required this.rightTitle,
    required this.rightEmoji,
  });
}

class MatchPairsScreen extends StatefulWidget {
  const MatchPairsScreen({super.key});

  @override
  State<MatchPairsScreen> createState() => _MatchPairsScreenState();
}

class _MatchPairsScreenState extends State<MatchPairsScreen> {
  final List<MatchPair> _allPairs = [
    MatchPair(id: '1', leftTitle: 'Davi', leftEmoji: '👑', rightTitle: 'Pedra e Funda', rightEmoji: '🪨'),
    MatchPair(id: '2', leftTitle: 'Moisés', leftEmoji: '📜', rightTitle: 'Cajado e Mar', rightEmoji: '🌊'),
    MatchPair(id: '3', leftTitle: 'Noé', leftEmoji: '⛵', rightTitle: 'Arca e Arco-Íris', rightEmoji: '🌈'),
    MatchPair(id: '4', leftTitle: 'Jonas', leftEmoji: '🌊', rightTitle: 'Grande Peixe', rightEmoji: '🐳'),
    MatchPair(id: '5', leftTitle: 'Daniel', leftEmoji: '🦁', rightTitle: 'Cova dos Leões', rightEmoji: '🏰'),
    MatchPair(id: '6', leftTitle: 'Jesus', leftEmoji: '❤️', rightTitle: 'Pães e Peixes', rightEmoji: '🥖'),
  ];

  List<MatchPair> _activePairs = [];
  List<MatchPair> _shuffledRight = [];
  
  String? _selectedLeftId;
  Set<String> _matchedIds = {};
  String _lessonTheme = 'Aula de Hoje';

  @override
  void initState() {
    super.initState();
    _loadLessonData();
    _setupRound();
  }

  Future<void> _loadLessonData() async {
    final plan = await DatabaseHelper.instance.fetchLessonOfTheWeek();
    if (plan != null) {
      setState(() {
        _lessonTheme = plan.title;
      });
    }
  }

  void _setupRound() {
    final List<MatchPair> pool = List.from(_allPairs)..shuffle();
    _activePairs = pool.take(4).toList();
    _shuffledRight = List.from(_activePairs)..shuffle();
    
    setState(() {
      _selectedLeftId = null;
      _matchedIds.clear();
    });
  }

  void _selectLeft(String id) {
    if (_matchedIds.contains(id)) return;
    setState(() {
      _selectedLeftId = id;
    });
  }

  void _selectRight(String id) {
    if (_selectedLeftId == null || _matchedIds.contains(id)) return;

    if (_selectedLeftId == id) {
      // Match correto!
      AudioService.instance.playVictory();
      setState(() {
        _matchedIds.add(id);
        _selectedLeftId = null;
      });

      if (_matchedIds.length == _activePairs.length) {
        _showVictoryDialog();
      }
    } else {
      // Incorreto
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tente novamente! Associe a figura correspondente.'),
          duration: Duration(milliseconds: 1000),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _selectedLeftId = null;
      });
    }
  }

  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                'Parabéns!',
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você conectou todos os personagens e símbolos bíblicos corretamente!',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setupRound();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Jogar Novamente', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulCeleste,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Ligue os Pares 🔗',
          style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, color: AppColors.azulCeleste, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Toque em um Personagem à esquerda e depois no seu Item à direita para ligar!',
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    // Coluna da Esquerda (Personagens)
                    Expanded(
                      child: ListView.separated(
                        itemCount: _activePairs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _activePairs[index];
                          final isMatched = _matchedIds.contains(item.id);
                          final isSelected = _selectedLeftId == item.id;

                          return GestureDetector(
                            onTap: () => _selectLeft(item.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isMatched
                                    ? Colors.green.shade50
                                    : (isSelected ? Colors.blue.shade100 : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isMatched
                                      ? Colors.green
                                      : (isSelected ? AppColors.azulCeleste : Colors.grey.shade300),
                                  width: isSelected || isMatched ? 2.5 : 1,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(color: AppColors.azulCeleste.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)
                                ],
                              ),
                              child: Row(
                                children: [
                                  Text(item.leftEmoji, style: const TextStyle(fontSize: 28)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.leftTitle,
                                      style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isMatched ? Colors.green.shade800 : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (isMatched) const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Coluna da Direita (Itens / Símbolos)
                    Expanded(
                      child: ListView.separated(
                        itemCount: _shuffledRight.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _shuffledRight[index];
                          final isMatched = _matchedIds.contains(item.id);

                          return GestureDetector(
                            onTap: () => _selectRight(item.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isMatched ? Colors.green.shade50 : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isMatched ? Colors.green : Colors.grey.shade300,
                                  width: isMatched ? 2.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(item.rightEmoji, style: const TextStyle(fontSize: 28)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.rightTitle,
                                      style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isMatched ? Colors.green.shade800 : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (isMatched) const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
