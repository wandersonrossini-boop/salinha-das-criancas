import 'dart:convert';
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
  
  int _totalQuestions = 5;
  List<Team> _teams = [];
  Team? _activeTeam;
  
  late List<Map<String, dynamic>> _questions;
  Map<String, dynamic>? _tiebreakerQuestion;
  int _currentQuestionIndex = 0;
  
  int _streak = 0;
  int _timeLeft = 30;
  Timer? _timer;
  
  bool _answered = false;
  String? _selectedOption;
  
  int _totalCorrectAnswers = 0;
  int _totalSecondsSpent = 0;
  List<Map<String, dynamic>>? _activeLessonQuestions;
  String _lessonTitle = '';
  String _lessonAgeGroup = '';

  Map<int, int> _sessionScores = {};

  final List<Map<String, dynamic>> _defaultPool = [
    {
      'question': 'Quem derrotou o gigante Golias?',
      'options': ['Moisés', 'Davi', 'Paulo', 'Pedro'],
      'answer': 'Davi',
      'curiosidade': 'Davi usou apenas uma pedra e uma funda, mostrando que a confiança em Deus vence qualquer obstáculo!',
      'ageGroup': '6-8 anos',
      'questionType': 'interpretation',
      'difficulty': 'medium'
    },
    {
      'question': 'Quem foi engolido por um grande peixe?',
      'options': ['Elias', 'João', 'Jonas', 'Noé'],
      'answer': 'Jonas',
      'curiosidade': 'Jonas ficou três dias na barriga do peixe até se arrepender e obedecer ao chamado de Deus.',
      'ageGroup': '6-8 anos',
      'questionType': 'interpretation',
      'difficulty': 'medium'
    },
    {
      'question': 'Quantos dias e noites choveu no dilúvio?',
      'options': ['10', '40', '7', '100'],
      'answer': '40',
      'curiosidade': 'Depois dos 40 dias de chuva, Deus colocou o arco-íris nas nuvens como um pacto de amor.',
      'ageGroup': '6-8 anos',
      'questionType': 'interpretation',
      'difficulty': 'medium'
    },
    {
      'question': 'Quem abriu o Mar Vermelho?',
      'options': ['Abraão', 'Moisés', 'Josué', 'Davi'],
      'answer': 'Moisés',
      'curiosidade': 'Moisés estendeu seu cajado obedecendo a Deus, e um vento forte soprou abrindo caminho na água.',
      'ageGroup': '6-8 anos',
      'questionType': 'interpretation',
      'difficulty': 'medium'
    },
    {
      'question': 'Quem foi lançado na cova dos leões?',
      'options': ['Daniel', 'Sadraque', 'Ezequiel', 'José'],
      'answer': 'Daniel',
      'curiosidade': 'Daniel orava três vezes ao dia e Deus enviou um anjo para fechar a boca dos leões.',
      'ageGroup': '6-8 anos',
      'questionType': 'interpretation',
      'difficulty': 'medium'
    },
    {
      'question': 'Qual o nome do anjo que apareceu a Maria?',
      'options': ['Miguel', 'Gabriel', 'Rafael', 'Lúcifer'],
      'answer': 'Gabriel',
      'curiosidade': 'O anjo Gabriel trouxe a mensagem mais feliz da história: o nascimento de Jesus!',
      'ageGroup': '6-8 anos',
      'questionType': 'interpretation',
      'difficulty': 'medium'
    },
    {
      'question': 'Jesus multiplicou 5 pães e quantos peixinhos?',
      'options': ['2', '3', '5', '7'],
      'answer': '2',
      'curiosidade': 'Com apenas 5 pães e 2 peixinhos, Jesus alimentou mais de 5 mil pessoas e ainda sobrou comida!',
      'ageGroup': '6-8 anos',
      'questionType': 'interpretation',
      'difficulty': 'medium'
    },
    {
      'question': 'Quem foi o homem mais forte da Bíblia?',
      'options': ['Davi', 'Golias', 'Sansão', 'Saul'],
      'answer': 'Sansão',
      'curiosidade': 'A força de Sansão vinha do Espírito do Senhor, mas ele precisava guardar o segredo de consagrado.',
      'ageGroup': '6-8 anos',
      'questionType': 'interpretation',
      'difficulty': 'medium'
    },
    {
      'question': 'Onde Jesus nasceu?',
      'options': ['Jerusalém', 'Nazaré', 'Belém', 'Egito'],
      'answer': 'Belém',
      'curiosidade': 'Jesus nasceu em uma estrebaria em Belém e foi colocado em uma manjedoura.',
      'ageGroup': '6-8 anos',
      'questionType': 'interpretation',
      'difficulty': 'medium'
    },
    {
      'question': 'Quantos discípulos Jesus tinha?',
      'options': ['10', '12', '7', '14'],
      'answer': '12',
      'curiosidade': 'Jesus chamou 12 homens comuns para andarem com Ele e pregarem a Palavra pelo mundo todo.',
      'ageGroup': '6-8 anos',
      'questionType': 'interpretation',
      'difficulty': 'medium'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    await _loadTeams();
    await _loadQuestionsFromActiveLesson();
  }

  String _cleanOptionText(String option) {
    String clean = option.trim();
    final regexPrefix = RegExp(r'^[a-dA-D]\s*[\)\-\.]\s*|^[rR]esposta:\s*');
    clean = clean.replaceFirst(regexPrefix, '');
    return clean.trim();
  }

  Future<void> _loadQuestionsFromActiveLesson() async {
    if (widget.customQuestions != null && widget.customQuestions!.isNotEmpty) {
      return;
    }
    final plan = await DatabaseHelper.instance.fetchLessonOfTheWeek();
    if (plan != null) {
      setState(() {
        _lessonTitle = plan.title;
        _lessonAgeGroup = plan.ageGroup;
      });
      if (plan.questions.isNotEmpty) {
        try {
          final decoded = jsonDecode(plan.questions);
          if (decoded is List && decoded.isNotEmpty) {
            final List<Map<String, dynamic>> parsed = [];

            for (var x in decoded) {
              final map = Map<String, dynamic>.from(x);

              // Metadados estritamente verificados
              final questionAgeGroup = map['ageGroup']?.toString();
              if (questionAgeGroup != null) {
                if (plan.ageGroup.isNotEmpty && questionAgeGroup != plan.ageGroup) {
                  continue; // Ignorar por incompatibilidade de idade estruturada
                }
              }

              if (map['options'] is! List) {
                map['options'] = [
                  map['answer'] ?? '',
                  'Opção B',
                  'Opção C',
                  'Opção D'
                ];
              }
              
              List<String> rawOptions = (map['options'] as List).map((e) => e.toString()).toList();
              List<String> cleanedOptions = rawOptions.map((e) => _cleanOptionText(e)).toList();
              final cleanCorrectAnswer = _cleanOptionText(map['answer'] ?? '');
              cleanedOptions.shuffle();
              
              map['options'] = cleanedOptions;
              map['answer'] = cleanCorrectAnswer;
              parsed.add(map);
            }

            setState(() {
              _activeLessonQuestions = parsed;
              _totalQuestions = parsed.isEmpty ? 0 : (parsed.length < 10 ? parsed.length : 10);
            });
          }
        } catch (e) {
          debugPrint('Erro ao parsear questões do plano de aula: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _teams = [
        Team(id: 1, name: 'Grupo A 🔵', color: 0xFF2196F3, points: 0),
        Team(id: 2, name: 'Grupo B 🟡', color: 0xFFFFB300, points: 0),
      ];
      _activeTeam = _teams.first;
      
      _sessionScores.clear();
      for (var t in _teams) {
        _sessionScores[t.id!] = 0;
      }
    });
  }

  int _getAvailableCount() {
    return _activeLessonQuestions != null ? _activeLessonQuestions!.length : _defaultPool.length;
  }

  void _startGame() {
    if (_activeTeam == null || _totalQuestions <= 0) return;
    
    int available = _getAvailableCount();
    if (_totalQuestions > available) {
      _totalQuestions = available;
    }

    List<Map<String, dynamic>> sourcePool = [];
    if (widget.customQuestions != null && widget.customQuestions!.isNotEmpty) {
      sourcePool = List.from(widget.customQuestions!);
    } else if (_activeLessonQuestions != null && _activeLessonQuestions!.isNotEmpty) {
      sourcePool = List.from(_activeLessonQuestions!);
    } else {
      final List<Map<String, dynamic>> cleanedDefault = _defaultPool.map((x) {
        final map = Map<String, dynamic>.from(x);
        List<String> rawOptions = (map['options'] as List).map((e) => e.toString()).toList();
        List<String> cleanedOptions = rawOptions.map((e) => _cleanOptionText(e)).toList();
        map['options'] = cleanedOptions;
        map['answer'] = _cleanOptionText(map['answer'] ?? '');
        cleanedOptions.shuffle();
        return map;
      }).toList();
      sourcePool = cleanedDefault;
    }

    sourcePool.shuffle();

    // Alocação Prévia do Pool de Desempate (Pre-allocated Tiebreaker)
    if (sourcePool.length > _totalQuestions) {
      _questions = sourcePool.take(_totalQuestions).toList();
      _tiebreakerQuestion = sourcePool[_totalQuestions];
    } else if (sourcePool.length > 1) {
      _totalQuestions = sourcePool.length - 1;
      _questions = sourcePool.take(_totalQuestions).toList();
      _tiebreakerQuestion = sourcePool.last;
    } else {
      _questions = sourcePool.take(_totalQuestions).toList();
      _tiebreakerQuestion = null;
    }

    setState(() {
      _currentQuestionIndex = 0;
      _streak = 0;
      _totalCorrectAnswers = 0;
      _totalSecondsSpent = 0;
      _answered = false;
      _selectedOption = null;
      
      for (var t in _teams) {
        _sessionScores[t.id!] = 0;
      }
      
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
        _processAnswer(false, null);
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

    _processAnswer(isCorrect, option);
  }

  Future<void> _processAnswer(bool isCorrect, String? selectedOption) async {
    if (!mounted) return;

    if (isCorrect) {
      _streak++;
      _totalCorrectAnswers++;
      
      int pointsEarned = 10;
      
      final currentScore = _sessionScores[_activeTeam!.id!] ?? 0;
      _sessionScores[_activeTeam!.id!] = currentScore + pointsEarned;
      
      final updatedTeam = Team(
        id: _activeTeam!.id,
        name: _activeTeam!.name,
        color: _activeTeam!.color,
        points: _activeTeam!.points + pointsEarned,
      );
      if (updatedTeam.id != 0 && updatedTeam.id != null) {
        await DatabaseHelper.instance.updateTeam(updatedTeam);
      }
    } else {
      _streak = 0;
    }
  }

  void _avancarQuiz() {
    if (_currentQuestionIndex < _totalQuestions - 1) {
      int currentIndex = _teams.indexWhere((t) => t.id == _activeTeam!.id);
      int nextIndex = (currentIndex + 1) % _teams.length;

      setState(() {
        _currentQuestionIndex++;
        _answered = false;
        _selectedOption = null;
        _activeTeam = _teams[nextIndex];
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
      setState(() {
        _activeTeam = _teams[nextIndex];
        _answered = false;
        _selectedOption = null;
      });
      _startTimer();
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Regras do Quiz', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
        content: const Text(
          '1. As equipes jogam em turnos.\n'
          '2. Resposta Correta garante 100 pontos base + bônus de tempo.\n'
          '3. Se a equipe errar ou o tempo acabar, a vez pode ser passada para a outra equipe.\n'
          '4. Quem acumular a maior pontuação no final é o vencedor!'
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quiz Bíblico', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.azulCeleste),
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
      return const Center(child: Text("Carregando equipes..."));
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
    int available = _getAvailableCount();
    
    List<int> chipValues = [];
    if (available < 5) {
      chipValues = available > 0 ? [available] : [];
    } else {
      chipValues = [5, 10, 15, 20].where((v) => v <= available).toList();
      if (chipValues.isEmpty && available > 0) {
        chipValues = [available];
      }
    }

    if (chipValues.isNotEmpty && !chipValues.contains(_totalQuestions)) {
      _totalQuestions = chipValues.first;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.azulCeleste.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.azulCeleste.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lessonTitle.isNotEmpty ? 'Aula: $_lessonTitle' : 'Modo Geral ou Temático',
                      style: const TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lessonAgeGroup.isNotEmpty 
                          ? 'Turma: $_lessonAgeGroup • $available perguntas disponíveis'
                          : 'Perguntas padrão do app • $available disponíveis',
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('Nº de Perguntas para Jogar:', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              if (available < 5) ...[
                Text(
                  '$available perguntas disponíveis — todas serão utilizadas',
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.laranjaCriativo),
                ),
                const SizedBox(height: 8),
              ],
              if (chipValues.isEmpty)
                const Text(
                  'Nenhuma pergunta disponível para esta aula.',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: chipValues.map((int val) {
                    final active = (_totalQuestions == val);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('$val'),
                        selected: active,
                        onSelected: (selected) {
                          if (selected) setState(() => _totalQuestions = val);
                        },
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              
              const Text('Escolha a Equipe Iniciante:', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? tColor.withOpacity(0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? tColor : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: tColor, shape: BoxShape.circle),
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
              const SizedBox(height: 24),
              
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (chipValues.isEmpty || _totalQuestions <= 0) ? null : _startGame,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Iniciar Quiz', style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildScoreboard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _teams.map((t) {
        final tColor = Color(t.color);
        final isTurn = (_activeTeam?.id == t.id);
        final score = _sessionScores[t.id] ?? 0;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isTurn ? tColor.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isTurn ? tColor : Colors.grey.shade200, width: isTurn ? 2 : 1),
            boxShadow: [
              if (isTurn)
                BoxShadow(color: tColor.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))
            ],
          ),
          child: Column(
            children: [
              Text(
                t.name.split(' ').first,
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: tColor, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '$score pts',
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: tColor, fontSize: 18),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlaying() {
    final question = _questions[_currentQuestionIndex];
    final correctAnswer = question['answer'] as String;
    
    Color timerColor = AppColors.azulCeleste;
    if (_timeLeft <= 10 && _timeLeft > 5) {
      timerColor = Colors.amber;
    } else if (_timeLeft <= 5) {
      timerColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          _buildScoreboard(),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pergunta ${_currentQuestionIndex + 1} de $_totalQuestions',
                style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              _AnimatedTimerCircle(timeLeft: _timeLeft, timerColor: timerColor),
            ],
          ),
          const SizedBox(height: 12),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _totalQuestions,
              minHeight: 4,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.azulCeleste,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              question['question'],
              style: const TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: (question['options'] as List).length,
              itemBuilder: (context, index) {
                final option = question['options'][index] as String;
                final cleanOption = option;
                final prefix = String.fromCharCode(65 + index);

                Color bg = Colors.white;
                Color borderCol = Colors.grey.shade200;
                Color textCol = Colors.black87;

                if (_answered) {
                  if (cleanOption == correctAnswer) {
                    bg = Colors.green.shade50;
                    borderCol = Colors.green;
                    textCol = Colors.green.shade800;
                  } else if (cleanOption == _selectedOption) {
                    bg = Colors.red.shade50;
                    borderCol = Colors.red;
                    textCol = Colors.red.shade800;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: _answered ? null : () => _checkAnswer(cleanOption),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderCol, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: borderCol.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              prefix,
                              style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cleanOption,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textCol,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_answered) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100, width: 0.8),
              ),
              child: Row(
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      question['curiosidade'] ?? 'Resposta correta: $correctAnswer',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _switchTeam,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Passar a Vez', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _avancarQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulCeleste,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Próxima Pergunta', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinished() {
    List<Map<String, dynamic>> finalRanking = [];
    for (var t in _teams) {
      finalRanking.add({
        'name': t.name,
        'color': t.color,
        'points': _sessionScores[t.id] ?? 0,
      });
    }
    finalRanking.sort((a, b) => b['points'].compareTo(a['points']));
    
    bool isTie = finalRanking.length > 1 && finalRanking[0]['points'] == finalRanking[1]['points'];
    bool hasTieBreakQuestion = _tiebreakerQuestion != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, size: 54, color: AppColors.amareloSol),
              const SizedBox(height: 12),
              const Text(
                'FIM DE RODADA',
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.azulCeleste),
              ),
              const SizedBox(height: 20),
              
              if (isTie) ...[
                const Text('HOUVE UM EMPATE', style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.alerta)),
                const SizedBox(height: 16),
                if (hasTieBreakQuestion) ...[
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Use pre-allocated tiebreaker
                        _totalQuestions += 1;
                        _questions.add(_tiebreakerQuestion!);
                        _currentQuestionIndex = _totalQuestions - 1;
                        _tiebreakerQuestion = null; // Used
                        _answered = false;
                        _selectedOption = null;
                        _state = QuizState.playing;
                      });
                      _startTimer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.alerta,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Rodada de Desempate', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                  ),
                ] else ...[
                  const Text(
                    'Terminou empatado! As duas equipes foram muito bem.',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                ],
              ] else ...[
                Text(
                  'Equipe Vencedora:\n${finalRanking.first['name']}',
                  style: TextStyle(fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.bold, color: Color(finalRanking.first['color'])),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Parabéns a todas as crianças! Vocês jogaram muito bem!',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                ...finalRanking.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r['name'], style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${r['points']} pts', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Color(r['color']), fontSize: 14)),
                    ],
                  ),
                )),
              ],
              
              const SizedBox(height: 24),
              SizedBox(
                height: 46,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _state = QuizState.setup;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulCeleste,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Jogar Novamente', style: TextStyle(fontFamily: 'Fredoka', fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar aos Jogos', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: widget.timeLeft / 30,
              strokeWidth: 4,
              backgroundColor: Colors.grey.shade200,
              color: widget.timerColor,
            ),
          ),
          Text(
            '${widget.timeLeft}',
            style: TextStyle(fontFamily: 'Fredoka', fontSize: 15, fontWeight: FontWeight.bold, color: widget.timerColor),
          ),
        ],
      ),
    );
  }
}
