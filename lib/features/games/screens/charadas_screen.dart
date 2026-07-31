import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
import '../../teams/models/team.dart';
import '../../students/models/student.dart';

class CharadasScreen extends StatefulWidget {
  const CharadasScreen({super.key});

  @override
  State<CharadasScreen> createState() => _CharadasScreenState();
}

class _CharadasScreenState extends State<CharadasScreen> {
  bool _gameStarted = false;
  String _activeLessonTitle = 'Carregando...';
  String _ageGroup = '6-8 anos';
  int _totalRounds = 5;
  String _gameType = 'Dicas';
  String _timerConfig = '30s';

  List<Team> _teams = [];
  Team? _selectedTeam;
  List<Student> _students = [];
  Student? _selectedStudent;
  bool _assignToTeam = true;

  int _currentRound = 1;
  int _timeLeft = 30;
  Timer? _timer;
  bool _timerRunning = false;
  
  Map<int, int> _sessionScores = {};

  final List<Map<String, dynamic>> _personagens = [
    {
      'nome': 'Davi',
      'emoji': '👑🎵',
      'historia': 'Foi um pastor de ovelhas que virou rei e escreveu muitos salmos.',
      'referencia': '1 Samuel 16',
      'categoria': 'Antigo Testamento',
      'dicas': [
        'Fui um pastor de ovelhas no campo.',
        'Toquei harpa para acalmar o rei Saul.',
        'Derrotei o gigante Golias com uma funda.'
      ],
      'mimicas': [
        'Imite tocar harpa suavemente',
        'Imite girar uma funda no ar e lançar',
        'Imite a queda de um gigante no chão'
      ]
    },
    {
      'nome': 'Jonas',
      'emoji': '🐳⛵',
      'historia': 'Tentou fugir de Deus de navio, mas foi engolido por um grande peixe.',
      'referencia': 'Livro de Jonas',
      'categoria': 'Antigo Testamento',
      'dicas': [
        'Fugi da presença do Senhor em um navio.',
        'Fui jogado no mar durante uma grande tempestade.',
        'Fiquei três dias na barriga de um grande peixe!'
      ],
      'mimicas': [
        'Imite o balanço de um barco na tempestade',
        'Imite nadar desesperadamente',
        'Imite abrir uma bocarra gigante de peixe'
      ]
    },
    {
      'nome': 'Moisés',
      'emoji': '🌊⛰️',
      'historia': 'Liderou o povo no deserto e recebeu os 10 Mandamentos de Deus.',
      'referencia': 'Êxodo 3',
      'categoria': 'Antigo Testamento',
      'dicas': [
        'Fui colocado em um cesto de vime no rio Nilo.',
        'Deus falou comigo por meio de uma sarça em chamas.',
        'Abri o Mar Vermelho estendendo o meu cajado.'
      ],
      'mimicas': [
        'Imite segurar e estender um cajado alto',
        'Imite flutuar suavemente como um cesto',
        'Imite escrever tábuas de pedra com o dedo'
      ]
    },
    {
      'nome': 'Noé',
      'emoji': '🚢🌈',
      'historia': 'Construiu a grande Arca de madeira para salvar os animais do Dilúvio.',
      'referencia': 'Gênesis 6',
      'categoria': 'Antigo Testamento',
      'dicas': [
        'Deus mandou eu construir algo muito grande de madeira.',
        'Coloquei casais de todos os tipos de animais lá dentro.',
        'Sobrevivi ao dilúvio flutuando em águas profundas.'
      ],
      'mimicas': [
        'Imite cortar e martelar madeira',
        'Imite fazer som e gestos de chuva caindo',
        'Imite o caminhar de diferentes animais'
      ]
    },
    {
      'nome': 'Daniel',
      'emoji': '🦁🙏',
      'historia': 'Fiel servo de Deus jogado na cova dos leões, que foi salvo por um anjo.',
      'referencia': 'Daniel 6',
      'categoria': 'Antigo Testamento',
      'dicas': [
        'Eu orava a Deus fielmente três vezes ao dia.',
        'Fui proibido de orar, mas continuei orando.',
        'Fui lançado em uma cova cheia de leões famintos.'
      ],
      'mimicas': [
        'Imite juntar as mãos e orar de joelhos',
        'Imite o rugido de um leão abrindo a boca',
        'Imite um anjo pousando e fechando a boca do leão'
      ]
    },
    {
      'nome': 'Pedro',
      'emoji': '⛵🐟',
      'historia': 'Apóstolo pescador de homens e líder da igreja primitiva.',
      'referencia': 'Mateus 14',
      'categoria': 'Novo Testamento',
      'dicas': [
        'Fui um pescador antes de seguir Jesus.',
        'Tentei andar sobre as águas, mas senti medo e afundei.',
        'Neguei conhecer Jesus três vezes antes do galo cantar.'
      ],
      'mimicas': [
        'Imite lançar e recolher uma rede de pesca',
        'Imite caminhar com desequilíbrio e afundar',
        'Imite um galo batendo asas e cantando'
      ]
    },
    {
      'nome': 'José',
      'emoji': '🌾👑',
      'historia': 'Tinha túnica colorida, foi vendido pelos irmãos e virou governador no Egito.',
      'referencia': 'Gênesis 37',
      'categoria': 'Antigo Testamento',
      'dicas': [
        'Ganhei uma linda túnica colorida do meu pai.',
        'Fui vendido como escravo pelos meus irmãos.',
        'Interpretei os sonhos do Faraó e virei governador.'
      ],
      'mimicas': [
        'Imite vestir e exibir uma roupa muito bonita',
        'Imite dormir e apontar para a cabeça simulando sonhos',
        'Imite colocar uma coroa e agir como governador'
      ]
    },
  ];

  late Map<String, dynamic> _personagemAtual;
  List<Map<String, dynamic>> _activePool = [];
  List<Map<String, dynamic>> _roundCharacters = [];
  int _dicasReveladas = 0;
  bool _isMimicRound = false;
  bool _revealSecretPressed = false;

  @override
  void initState() {
    super.initState();
    _activePool = List.from(_personagens);
    _loadTeams();
    _loadActiveLessonPlan();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    final teams = await DatabaseHelper.instance.fetchAllTeams();
    final students = await DatabaseHelper.instance.fetchAllStudents();
    setState(() {
      _teams = teams;
      if (_teams.isEmpty) {
        _teams = [
          Team(id: 1, name: 'Equipe Azul 🔵', color: 0xFF2196F3, points: 0),
          Team(id: 2, name: 'Equipe Laranja 🟠', color: 0xFFFF5722, points: 0),
        ];
      }
      _selectedTeam = _teams.first;
      _students = students;
      if (_students.isNotEmpty) {
        _selectedStudent = _students.first;
      }
      
      _sessionScores.clear();
      for (var t in _teams) {
        _sessionScores[t.id!] = 0;
      }
    });
  }

  Future<void> _loadActiveLessonPlan() async {
    final plan = await DatabaseHelper.instance.fetchLessonOfTheWeek();
    if (plan != null) {
      setState(() {
        _activeLessonTitle = plan.title;
        _ageGroup = plan.ageGroup;
      });
      final titleLower = plan.title.toLowerCase();
      final storyLower = plan.storyTopics.toLowerCase();
      final relevant = _personagens.where((p) {
        final nome = p['nome'].toString().toLowerCase();
        return titleLower.contains(nome) || storyLower.contains(nome);
      }).toList();
      
      if (relevant.isNotEmpty) {
        setState(() {
          _activePool = relevant;
          _totalRounds = _activePool.length < _totalRounds ? _activePool.length : _totalRounds;
        });
      }
    } else {
      setState(() {
        _activeLessonTitle = 'Geral ou Temático';
      });
    }
  }

  void _startGame() {
    int available = _activePool.length;
    if (_totalRounds > available) {
      _totalRounds = available;
    }

    setState(() {
      _currentRound = 1;
      _gameStarted = true;
      _sessionScores.clear();
      for (var t in _teams) {
        _sessionScores[t.id!] = 0;
      }
      
      // Shuffle active pool without repeating characters during this game session
      final List<Map<String, dynamic>> tempPool = List.from(_activePool);
      tempPool.shuffle();
      _roundCharacters = tempPool.take(_totalRounds).toList();
      
      _prepareRound();
    });
  }

  void _prepareRound() {
    _timer?.cancel();
    _timerRunning = false;
    _revealSecretPressed = false;
    
    if (_gameType == 'Dicas') {
      _isMimicRound = false;
    } else if (_gameType == 'Mímica') {
      _isMimicRound = true;
    } else {
      _isMimicRound = Random().nextBool();
    }

    // Pull unique character sequentially
    _personagemAtual = _roundCharacters[_currentRound - 1];
    _dicasReveladas = 0;

    // Adjust hints order if age group is older kids (7-11)
    final ageLower = _ageGroup.toLowerCase();
    if (ageLower.contains('7-11') || ageLower.contains('9-11') || ageLower.contains('6-8')) {
      // Invert list so the most conclusive hints (often index 2 in raw pool) are presented last (as Dica 3)
      final List<String> rawDicas = List<String>.from(_personagemAtual['dicas']);
      // We want index 0 to be the most indirect one, and index 2 to be the most conclusive one.
      // Our default pool already has index 0 as broad, index 2 as easiest. No changes required.
    }

    if (_timerConfig == 'Sem Tempo') {
      _timeLeft = 0;
    } else {
      _timeLeft = int.parse(_timerConfig.replaceAll('s', ''));
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        setState(() {
          _timerRunning = false;
        });
        _showRoundTimeout();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
    });
  }

  void _resumeTimer() {
    if (_timerConfig != 'Sem Tempo' && _timeLeft > 0) {
      _startTimer();
    }
  }

  int _calculatePointsEarned() {
    if (_isMimicRound) return 20;
    if (_dicasReveladas == 1) return 30;
    if (_dicasReveladas == 2) return 20;
    return 10;
  }

  void _abrirPainelPalpite() {
    _pauseTimer();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Registrar Palpite', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Quem respondeu?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Equipe')),
                          selected: _assignToTeam,
                          onSelected: (val) => setModalState(() => _assignToTeam = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Aluno')),
                          selected: !_assignToTeam,
                          onSelected: (val) => setModalState(() => _assignToTeam = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_assignToTeam)
                    DropdownButtonFormField<Team>(
                      value: _selectedTeam,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      items: _teams.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                      onChanged: (val) => setModalState(() => _selectedTeam = val),
                    )
                  else
                    DropdownButtonFormField<Student>(
                      value: _selectedStudent,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      items: _students.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                      onChanged: (val) => setModalState(() => _selectedStudent = val),
                    ),
                  const SizedBox(height: 18),
                  const Text('O palpite estava correto?', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _aplicarChuteAcerto();
                          },
                          icon: const Icon(Icons.check, color: Colors.white, size: 16),
                          label: const Text('Sim', style: TextStyle(fontFamily: 'Fredoka', color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _aplicarChuteErro();
                          },
                          icon: const Icon(Icons.close, color: Colors.white, size: 16),
                          label: const Text('Não', style: TextStyle(fontFamily: 'Fredoka', color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade400,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _aplicarChuteAcerto() {
    int points = _calculatePointsEarned();
    
    if (_assignToTeam && _selectedTeam != null) {
      final currentScore = _sessionScores[_selectedTeam!.id!] ?? 0;
      _sessionScores[_selectedTeam!.id!] = currentScore + points;
    }

    final winnerName = _assignToTeam ? (_selectedTeam?.name ?? 'Equipe') : (_selectedStudent?.name ?? 'Aluno');
    _showRoundWinnerDialog(winnerName, points);
  }

  void _aplicarChuteErro() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ainda não foi dessa vez', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Colors.orange)),
        content: const Text('Deseja continuar tentando com novos palpites ou prefere revelar a resposta agora?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resumeTimer();
            },
            child: const Text('Continuar tentando'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showRoundWinnerDialog('Ninguém', 0);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.laranjaCriativo, foregroundColor: Colors.white),
            child: const Text('Revelar resposta'),
          ),
        ],
      ),
    );
  }

  void _showRoundTimeout() {
    _showRoundWinnerDialog('Ninguém', 0);
  }

  void _showRoundWinnerDialog(String winnerName, int pointsEarned) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pointsEarned > 0 ? 'Acerto' : 'Fim do Tempo',
                  style: const TextStyle(fontFamily: 'Fredoka', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.azulCeleste),
                ),
                const SizedBox(height: 12),
                if (pointsEarned > 0) ...[
                  Text('$winnerName acertou!', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('+$pointsEarned pontos!', style: const TextStyle(fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                ] else ...[
                  const Text('O segredo foi revelado sem acertos!', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Segredo: ${_personagemAtual['nome']} ${_personagemAtual['emoji']}',
                  style: const TextStyle(fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _personagemAtual['historia'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                  child: Text('Ref: ${_personagemAtual['referencia']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (_currentRound < _totalRounds) {
                        setState(() {
                          _currentRound++;
                        });
                        _prepareRound();
                      } else {
                        _showEndGameDialog();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulCeleste,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentRound < _totalRounds ? 'Próxima Rodada' : 'Ver Resultados',
                      style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEndGameDialog() {
    List<Map<String, dynamic>> rank = [];
    for (var t in _teams) {
      rank.add({
        'name': t.name,
        'points': _sessionScores[t.id] ?? 0,
        'color': t.color,
      });
    }
    rank.sort((a, b) => b['points'].compareTo(a['points']));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Fim de Jogo', style: TextStyle(fontFamily: 'Fredoka', fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Parabéns a todos os participantes!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 18),
              ...rank.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r['name'], style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                    Text('${r['points']} pts', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Color(r['color']))),
                  ],
                ),
              )),
              const SizedBox(height: 24),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _gameStarted = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulCeleste,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Jogar Novamente', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Voltar ao Menu', style: TextStyle(color: Colors.grey)),
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
        title: const Text('Quem Sou Eu?', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _gameStarted ? _buildGamePlay() : _buildSetup(),
    );
  }

  Widget _buildSetup() {
    int available = _activePool.length;
    
    List<int> availableRounds = [5, 10, 15].where((r) => r <= available).toList();
    if (availableRounds.isEmpty && available > 0) {
      availableRounds = [available];
    }
    
    if (availableRounds.isNotEmpty && !availableRounds.contains(_totalRounds)) {
      _totalRounds = availableRounds.first;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.azulCeleste.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tema Ativo: $_activeLessonTitle', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 4),
                    Text('Faixa recomendada: $_ageGroup', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('Nº de Rodadas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              if (available == 1) ...[
                const Text(
                  'Este tema possui 1 personagem disponível.',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.laranjaCriativo),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: availableRounds.map((int val) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('$val rodadas'),
                      selected: _totalRounds == val,
                      onSelected: (selected) {
                        if (selected) setState(() => _totalRounds = val);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              const Text('Tipo de Rodada:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['Dicas', 'Mímica', 'Alternar'].map((String type) {
                  return ChoiceChip(
                    label: Text(type),
                    selected: _gameType == type,
                    onSelected: (selected) {
                      if (selected) setState(() => _gameType = type);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              const Text('Cronômetro:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['Sem Tempo', '30s', '45s', '60s'].map((String time) {
                  return ChoiceChip(
                    label: Text(time),
                    selected: _timerConfig == time,
                    onSelected: (selected) {
                      if (selected) setState(() => _timerConfig = time);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (availableRounds.isEmpty || _totalRounds <= 0) ? null : _startGame,
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text('Iniciar Partida', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulCeleste,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamePlay() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rodada $_currentRound de $_totalRounds',
                style: const TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isMimicRound ? AppColors.roxoAcolhedor.withOpacity(0.08) : AppColors.azulCeleste.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _isMimicRound ? AppColors.roxoAcolhedor : AppColors.azulCeleste),
                ),
                child: Text(
                  _isMimicRound ? 'Mímica' : 'Dicas',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _isMimicRound ? AppColors.roxoAcolhedor : AppColors.azulCeleste,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_timerConfig != 'Sem Tempo') ...[
            Center(
              child: Text(
                'Tempo Restante: $_timeLeft s',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _timeLeft <= 10 ? Colors.red : AppColors.azulCeleste,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!_isMimicRound) ...[
            ...List.generate(3, (index) {
              final revelada = index < _dicasReveladas;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    if (_dicasReveladas == index) {
                      setState(() => _dicasReveladas++);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          revelada ? Icons.lightbulb_outline_rounded : Icons.lock_outline_rounded,
                          color: revelada ? AppColors.azulCeleste : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dica ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                revelada ? _personagemAtual['dicas'][index] : 'Toque para revelar',
                                style: TextStyle(color: revelada ? Colors.black87 : Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Text('Mímica', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: AppColors.roxoAcolhedor)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTapDown: (_) => setState(() => _revealSecretPressed = true),
                    onTapUp: (_) => setState(() => _revealSecretPressed = false),
                    onTapCancel: () => setState(() => _revealSecretPressed = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _revealSecretPressed ? AppColors.roxoAcolhedor.withOpacity(0.08) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _revealSecretPressed ? AppColors.roxoAcolhedor : Colors.grey.shade300, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _revealSecretPressed ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            size: 32,
                            color: _revealSecretPressed ? AppColors.roxoAcolhedor : Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _revealSecretPressed
                                ? '${_personagemAtual['nome']} ${_personagemAtual['emoji']}'
                                : 'Pressione e segure para revelar o personagem',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _revealSecretPressed ? AppColors.roxoAcolhedor : Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Dicas físicas de gestos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ...(_personagemAtual['mimicas'] as List).map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text('• $m', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  )),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _abrirPainelPalpite,
              icon: const Icon(Icons.search_rounded, color: Colors.white),
              label: const Text('Dar um Palpite', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.laranjaCriativo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
