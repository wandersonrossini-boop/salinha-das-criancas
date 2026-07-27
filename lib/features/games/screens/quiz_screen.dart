import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
import '../../teams/models/team.dart';

enum QuizState { setup, playing, finished }

class QuizScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? customQuestions;
  const QuizScreen({super.key, this.customQuestions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  QuizState _state = QuizState.setup;
  
  int _totalQuestions = 10;
  List<Team> _teams = [];
  Team? _activeTeam;
  
  late List<Map<String, dynamic>> _questions;
  int _currentQuestionIndex = 0;
  
  int _streak = 0;
  int _timeLeft = 30;
  Timer? _timer;
  
  bool _answered = false;
  String? _selectedOption;
  
  // Game statistics
  int _totalCorrectAnswers = 0;
  int _totalSecondsSpent = 0;

  final List<Map<String, dynamic>> _defaultPool = [
    {
      'question': 'Quem derrotou o gigante Golias?',
      'options': ['Moisés', 'Davi', 'Paulo', 'Pedro'],
      'answer': 'Davi',
      'curiosidade': 'Davi usou apenas uma pedra e uma funda, mostrando que a confiança em Deus vence qualquer obstáculo!'
    },
    {
      'question': 'Quem foi engolido por um grande peixe?',
      'options': ['Elias', 'João', 'Jonas', 'Noé'],
      'answer': 'Jonas',
      'curiosidade': 'Jonas ficou três dias na barriga do peixe até se arrepender e obedecer ao chamado de Deus.'
    },
    {
      'question': 'Quantos dias e noites choveu no dilúvio?',
      'options': ['10', '40', '7', '100'],
      'answer': '40',
      'curiosidade': 'Depois dos 40 dias de chuva, Deus colocou o arco-íris nas nuvens como um pacto de amor.'
    },
    {
      'question': 'Quem abriu o Mar Vermelho?',
      'options': ['Abraão', 'Moisés', 'Josué', 'Davi'],
      'answer': 'Moisés',
      'curiosidade': 'Moisés estendeu seu cajado obedecendo a Deus, e um vento forte soprou abrindo caminho na água.'
    },
    {
      'question': 'Quem foi lançado na cova dos leões?',
      'options': ['Daniel', 'Sadraque', 'Ezequiel', 'José'],
      'answer': 'Daniel',
      'curiosidade': 'Daniel orava três vezes ao dia e Deus enviou um anjo para fechar a boca dos leões.'
    },
    {
      'question': 'Qual o nome do anjo que apareceu a Maria?',
      'options': ['Miguel', 'Gabriel', 'Rafael', 'Lúcifer'],
      'answer': 'Gabriel',
      'curiosidade': 'O anjo Gabriel trouxe a mensagem mais feliz da história: o nascimento de Jesus!'
    },
    {
      'question': 'Jesus multiplicou 5 pães e quantos peixinhos?',
      'options': ['2', '3', '5', '7'],
      'answer': '2',
      'curiosidade': 'Com apenas 5 pães e 2 peixinhos, Jesus alimentou mais de 5 mil pessoas e ainda sobrou comida!'
    },
    {
      'question': 'Quem foi o homem mais forte da Bíblia?',
      'options': ['Davi', 'Golias', 'Sansão', 'Saul'],
      'answer': 'Sansão',
      'curiosidade': 'A força de Sansão vinha do Espírito do Senhor, mas ele precisava guardar o segredo de consagrado.'
    },
    {
      'question': 'Onde Jesus nasceu?',
      'options': ['Jerusalém', 'Nazaré', 'Belém', 'Egito'],
      'answer': 'Belém',
      'curiosidade': 'Jesus nasceu em uma estrebaria em Belém e foi colocado em uma manjedoura.'
    },
    {
      'question': 'Quantos discípulos Jesus tinha?',
      'options': ['10', '12', '7', '14'],
      'answer': '12',
      'curiosidade': 'Jesus chamou 12 homens comuns para andarem com Ele e pregarem a Palavra pelo mundo todo.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    final teams = await DatabaseHelper.instance.fetchAllTeams();
    setState(() {
      _teams = teams;
      if (_teams.isEmpty) {
        _teams = [
          Team(id: 0, name: 'Top da Salinha 🔵', color: 0xFF2196F3, points: 0),
          Team(id: 0, name: 'Ovelhinhas do Pasto 🟠', color: 0xFFFF5722, points: 0),
        ];
      }
      _activeTeam = _teams.first;
    });
  }

  void _startGame() {
    if (_activeTeam == null) return;
    
    _defaultPool.shuffle();
    if (widget.customQuestions != null && widget.customQuestions!.isNotEmpty) {
      _questions = List.from(widget.customQuestions!);
      if (_totalQuestions > _questions.length) {
        _totalQuestions = _questions.length;
      }
    } else {
      _questions = _defaultPool.take(_totalQuestions).toList();
    }
    
    setState(() {
      _currentQuestionIndex = 0;
      _streak = 0;
      _totalCorrectAnswers = 0;
      _totalSecondsSpent = 0;
      _state = QuizState.playing;
    });
    _startTimer();
  }

  void _startTimer() {
    _timeLeft = 30;
    _answered = false;
    _selectedOption = null;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
          _totalSecondsSpent++;
        });
      } else {
        _timer?.cancel();
        _processAnswer(false);
      }
    });
  }

  void _checkAnswer(String option) {
    if (_answered) return;
    _timer?.cancel();
    
    final correctAnswer = _questions[_currentQuestionIndex]['answer'] as String;
    bool isCorrect = (option == correctAnswer);
    
    setState(() {
      _answered = true;
      _selectedOption = option;
    });

    _processAnswer(isCorrect);
  }

  Future<void> _processAnswer(bool isCorrect) async {
    if (!mounted) return;

    if (isCorrect) {
      _streak++;
      _totalCorrectAnswers++;
      final updatedTeam = Team(
        id: _activeTeam!.id,
        name: _activeTeam!.name,
        color: _activeTeam!.color,
        points: _activeTeam!.points + 10,
      );
      if (updatedTeam.id != 0) {
        await DatabaseHelper.instance.updateTeam(updatedTeam);
      }
      
      final idx = _teams.indexWhere((t) => t.id == _activeTeam!.id);
      if (idx != -1) {
        setState(() {
          _teams[idx] = updatedTeam;
          _activeTeam = updatedTeam; // Immediate score reflection
        });
      }

      if (_streak >= 5) {
        _switchTeam();
      }
    } else {
      _switchTeam();
    }

    // Exibe Feedback Bottom Dialog lúdico contendo Ficha de Curiosidade
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        final curiosidade = _questions[_currentQuestionIndex]['curiosidade'] ?? 'Os caminhos de Deus são incríveis!';
        final correctAnswer = _questions[_currentQuestionIndex]['answer'] as String;
        
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isCorrect ? '✔ Correto!' : '❌ Incorreto!',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (!isCorrect) ...[
                Text(
                  'A resposta correta era: $correctAnswer',
                  style: const TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 10),
              ],
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('📖 ', style: TextStyle(fontSize: 18)),
                        Text('Curiosidade Bíblica', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      curiosidade,
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, height: 1.35, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              _HoverScaleWrapper(
                onTap: () {
                  Navigator.pop(context);
                  _avancarQuiz();
                },
                colors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                child: const SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      'Próxima Pergunta ➡️',
                      style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _avancarQuiz() {
    if (_currentQuestionIndex < _totalQuestions - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answered = false;
        _selectedOption = null;
      });
      _startTimer();
    } else {
      setState(() {
        _state = QuizState.finished;
      });
    }
  }

  void _switchTeam() {
    _streak = 0;
    if (_teams.length > 1) {
      int currentIndex = _teams.indexWhere((t) => t.id == _activeTeam!.id);
      int nextIndex = (currentIndex + 1) % _teams.length;
      _activeTeam = _teams[nextIndex];
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Regras do Quiz 🧩', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
        content: const Text(
          '1. Escolha a equipe inicial.\n'
          '2. A equipe joga até acertar 5 perguntas seguidas.\n'
          '3. Se a equipe errar, passa a vez imediatamente para a rival.\n'
          '4. No final, quem tiver mais pontos ganha! Em caso de empate, vocês podem ativar a morte súbita.'
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Quiz Bíblico Competitivo', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.azulCeleste),
            onPressed: _showHelp,
            tooltip: 'Regras',
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_teams.isEmpty) {
      return const Center(child: Text("Cadastre equipes primeiro!"));
    }

    switch (_state) {
      case QuizState.setup:
        return _buildSetup();
      case QuizState.playing:
        return _buildPlaying();
      case QuizState.finished:
        return _buildFinished();
    }
  }

  Widget _buildSetup() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Card Premium
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.24), blurRadius: 16, offset: const Offset(0, 8))
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz Bíblico Competitivo 🏆',
                      style: TextStyle(fontFamily: 'Fredoka', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Prepare a próxima rodada da competição.',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('Quantidade de Perguntas', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [5, 10, 15, 20].map((int val) {
                  final active = (_totalQuestions == val);
                  return ChoiceChip(
                    label: Text('$val'),
                    selected: active,
                    onSelected: (selected) {
                      if (selected) setState(() => _totalQuestions = val);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              const Text('Equipe Inicial (Turno Inicial)', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _teams.map((Team team) {
                  final active = (_activeTeam?.id == team.id);
                  final tColor = Color(team.color);
                  
                  return GestureDetector(
                    onTap: () => setState(() => _activeTeam = team),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? tColor.withOpacity(0.12) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: active ? tColor : Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: tColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            team.name,
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: active ? tColor : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              _HoverScaleWrapper(
                onTap: _startGame,
                colors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                child: const SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        '▶ Iniciar Quiz',
                        style: TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreboard() {
    if (_teams.length == 1) {
      final t = _teams.first;
      final tColor = Color(t.color);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              t.name,
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: tColor, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '${t.points} pontos',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: tColor, fontSize: 20),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _teams.map((t) {
          final tColor = Color(t.color);
          final isTurn = (_activeTeam?.id == t.id);
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: tColor.withOpacity(isTurn ? 0.12 : 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tColor.withOpacity(isTurn ? 0.8 : 0.2), width: isTurn ? 2.5 : 1.0),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: tColor, size: 16),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily: 'Fredoka', 
                    fontWeight: FontWeight.bold, 
                    color: tColor, 
                    fontSize: isTurn ? 14 : 12
                  ),
                  child: Text('${t.name}: ${t.points}'),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlaying() {
    final question = _questions[_currentQuestionIndex];
    final activeColor = Color(_activeTeam!.color);
    
    // Timer color pulsing state
    Color timerColor = AppColors.azulCeleste;
    if (_timeLeft <= 10 && _timeLeft > 5) {
      timerColor = Colors.amber;
    } else if (_timeLeft <= 5 && _timeLeft > 2) {
      timerColor = Colors.orange;
    } else if (_timeLeft <= 2) {
      timerColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // 1. Placar
          _buildScoreboard(),
          const SizedBox(height: 12),
          
          // 2. Barra de Progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _totalQuestions,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.azulCeleste,
            ),
          ),
          const SizedBox(height: 8),
          
          // 3. Pergunta X de Y
          Text(
            'Pergunta ${_currentQuestionIndex + 1} de $_totalQuestions',
            style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          
          // 4. Cronometro
          _AnimatedTimerCircle(timeLeft: _timeLeft, timerColor: timerColor),
          const SizedBox(height: 10),
          
          // 5. Vez da Equipe
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: activeColor, width: 2)
            ),
            child: Text(
              'Vez da: ${_activeTeam!.name}',
              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 12, color: activeColor),
            ),
          ),
          const SizedBox(height: 16),
          
          // 6. Pergunta
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 70,
            alignment: Alignment.center,
            child: Text(
              question['question'],
              style: const TextStyle(fontFamily: 'Fredoka', fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          
          // 7. Alternativas
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: (question['options'] as List).length,
              itemBuilder: (context, index) {
                final option = question['options'][index] as String;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _HoverScaleWrapper(
                    onTap: _answered ? () {} : () => _checkAnswer(option),
                    colors: const [Colors.white, Color(0xFFF8FAFC)],
                    child: Container(
                      height: 60,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text(
                        option,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinished() {
    _teams.sort((a, b) => b.points.compareTo(a.points));
    bool isTie = _teams.length > 1 && _teams[0].points == _teams[1].points;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: AppColors.amareloSol.withOpacity(0.12), blurRadius: 40)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 12),
              const Text(
                'FIM DE RODADA! 🏁',
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.azulCeleste),
              ),
              const SizedBox(height: 20),
              
              if (isTie) ...[
                const Text('HOUVE UM EMPATE!', style: TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.alerta)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _totalQuestions = 1;
                      _state = QuizState.setup;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alerta,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Morte Súbita (Desempate)', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                Text(
                  'Equipe Vencedora:\n${_teams.first.name}',
                  style: const TextStyle(fontFamily: 'Fredoka', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.verdePasto),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pontuação final: ${_teams.first.points} pts',
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total de acertos: $_totalCorrectAnswers / $_totalQuestions',
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textSecondary),
                ),
                Text(
                  'Tempo médio: ${(_totalSecondsSpent / _totalQuestions).toStringAsFixed(1)}s por pergunta',
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
              
              const SizedBox(height: 28),
              _HoverScaleWrapper(
                onTap: () {
                  setState(() {
                    _state = QuizState.setup;
                  });
                },
                colors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                child: const SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      'Nova Rodada',
                      style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Encerrar', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Circular timer component with subtle pulse animations
class _AnimatedTimerCircle extends StatefulWidget {
  final int timeLeft;
  final Color timerColor;

  const _AnimatedTimerCircle({required this.timeLeft, required this.timerColor});

  @override
  State<_AnimatedTimerCircle> createState() => _AnimatedTimerCircleState();
}

class _AnimatedTimerCircleState extends State<_AnimatedTimerCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedTimerCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timeLeft <= 5) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: widget.timeLeft / 30,
              strokeWidth: 4.5,
              backgroundColor: Colors.grey.shade200,
              color: widget.timerColor,
            ),
          ),
          Text(
            '${widget.timeLeft}',
            style: TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: widget.timerColor),
          ),
        ],
      ),
    );
  }
}

// Interactive scale wrapper for clicks
class _HoverScaleWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final List<Color> colors;

  const _HoverScaleWrapper({
    required this.child,
    required this.onTap,
    required this.colors,
  });

  @override
  State<_HoverScaleWrapper> createState() => _HoverScaleWrapperState();
}

class _HoverScaleWrapperState extends State<_HoverScaleWrapper> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: widget.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.colors[0].withOpacity(_isPressed ? 0.12 : 0.06),
                blurRadius: _isPressed ? 6 : 12,
                spreadRadius: _isPressed ? -1 : -2,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.12),
                blurRadius: 4,
                spreadRadius: -1,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
