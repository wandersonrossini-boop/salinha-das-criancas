import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
import '../../teams/models/team.dart';
import '../../students/models/student.dart';
import '../../../core/components/mascot_assets.dart';

enum FaseJogo { preparando, emAndamento, chute, resultado, finalizado }

class CharadasScreen extends StatefulWidget {
  const CharadasScreen({super.key});

  @override
  State<CharadasScreen> createState() => _CharadasScreenState();
}

class _CharadasScreenState extends State<CharadasScreen> {
  List<Team> _teams = [];
  Team? _selectedTeam;

  List<Student> _students = [];
  Student? _selectedStudent;
  
  bool _assignToTeam = true; // Toggle between Team and Student

  int _timeLeft = 30;
  Timer? _timer;
  bool _timerRunning = false;

  // Bible Character System with illustrations, category, reference, and fun facts
  final List<Map<String, dynamic>> _personagens = [
    {
      'nome': 'Davi',
      'emoji': '👑🎵',
      'historia': 'Foi um pastor de ovelhas que virou rei e escreveu muitos salmos.',
      'referencia': '1 Samuel 16',
      'categoria': 'Antigo Testamento',
      'dicas': [
        'Fui um pastor de ovelhas no campo.',
        'Toquei harpa com muito amor para acalmar um rei.',
        'Derrotei o gigante Golias usando apenas uma funda e uma pedra.'
      ]
    },
    {
      'nome': 'Jonas',
      'emoji': '🐳⛵',
      'historia': 'Tentou fugir de Deus de navio, mas foi engolido por um grande peixe.',
      'referencia': 'Livro de Jonas',
      'categoria': 'Antigo Testamento',
      'dicas': [
        'Fugi da presença do Senhor em um grande barco.',
        'Fui jogado no mar durante uma assustadora tempestade.',
        'Fiquei três dias na barriga de um grande peixe!'
      ]
    },
    {
      'nome': 'Moisés',
      'emoji': '🌊⛰️',
      'historia': 'Liderou o povo no deserto e recebeu os 10 Mandamentos de Deus.',
      'referencia': 'Êxodo 3',
      'categoria': 'Antigo Testamento',
      'dicas': [
        'Fui colocado num cesto no rio Nilo quando bebê.',
        'Deus falou comigo através de uma sarça que ardia em fogo.',
        'Abri o Mar Vermelho estendendo meu cajado.'
      ]
    },
    {
      'nome': 'Noé',
      'emoji': '🚢🌈',
      'historia': 'Construiu a grande Arca de madeira para salvar os animais do Dilúvio.',
      'referencia': 'Gênesis 6',
      'categoria': 'Antigo Testamento',
      'dicas': [
        'Deus mandou que eu construísse algo muito grande de madeira.',
        'Coloquei casais de todos os tipos de animais lá dentro.',
        'Sobrevivi a um grande dilúvio flutuando na água.'
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
        'Fui proibido de orar, mas continuei fazendo minhas orações.',
        'Fui jogado numa cova cheia de leões famintos.'
      ]
    },
    {
      'nome': 'Pedro',
      'emoji': '⛵🐟',
      'historia': 'Apóstolo pescador de homens e líder da igreja primitiva.',
      'referencia': 'Mateus 14',
      'categoria': 'Novo Testamento',
      'dicas': [
        'Fui um pescador nas águas antes de seguir Jesus.',
        'Andei sobre as águas do mar, mas comecei a afundar.',
        'Neguei conhecer Jesus três vezes antes do galo cantar.'
      ]
    },
    {
      'nome': 'José',
      'emoji': '🌾👑',
      'historia': 'Tinha túnica colorida, foi vendido pelos irmãos e virou governador no Egito.',
      'referencia': 'Gênesis 37',
      'categoria': 'Antigo Testamento',
      'dicas': [
        'Ganhava túnicas coloridas do meu pai Jacó.',
        'Fui vendido como escravo pelos meus próprios irmãos.',
        'Virei governador do Egito após interpretar os sonhos do Faraó.'
      ]
    },
  ];

  late Map<String, dynamic> _personagemAtual;
  int _dicasReveladas = 0;
  bool _modoMimica = false;
  
  // UX State Management
  FaseJogo _fase = FaseJogo.preparando;
  int _rodadaAtual = 1;
  static const int _totalRodadas = 10;

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _sortearPersonagem(reiniciarRodadas: true);
  }

  void _sortearPersonagem({bool reiniciarRodadas = false}) {
    _timer?.cancel();
    setState(() {
      if (reiniciarRodadas) {
        _rodadaAtual = 1;
      } else if (_rodadaAtual < _totalRodadas) {
        _rodadaAtual++;
      } else {
        _rodadaAtual = 1;
      }
      _personagemAtual = _personagens[Random().nextInt(_personagens.length)];
      _dicasReveladas = 0;
      _fase = FaseJogo.preparando;
      _timeLeft = 30;
      _timerRunning = false;
    });
  }

  void _iniciarTimer(int segundos) {
    _timer?.cancel();
    setState(() {
      _timeLeft = segundos;
      _timerRunning = true;
      _fase = FaseJogo.emAndamento;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        timer.cancel();
        setState(() {
          _timerRunning = false;
          _fase = FaseJogo.finalizado;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Quem Sou Eu? 🕵️', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
        content: const Text(
          '1. Um personagem oculto é sorteado.\n'
          '2. No Modo Dicas, revele as dicas uma a uma.\n'
          '3. No Modo Mímica, um aluno vai à frente, vê o segredo e tenta imitar o personagem sem falar.\n'
          '4. Quem acertar primeiro leva os pontos!'
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

  Future<void> _loadTeams() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('teams');
    final studentMaps = await db.query('students', orderBy: 'name ASC');
    
    setState(() {
      _teams = maps.map((map) => Team.fromMap(map)).toList();
      if (_teams.isEmpty) {
        _teams = [
          Team(id: 0, name: 'Equipe Azul 🔵', color: 0xFF2196F3, points: 0),
          Team(id: 0, name: 'Equipe Laranja 🟠', color: 0xFFFF5722, points: 0),
        ];
      }
      _selectedTeam = _teams.first;
      
      _students = studentMaps.map((map) => Student.fromMap(map)).toList();
      if (_students.isNotEmpty) {
        _selectedStudent = _students.first;
      }
    });
  }

  // Opens bottom sheet to pick who answered
  void _abrirPainelChute() {
    _pauseTimer();
    setState(() {
      _fase = FaseJogo.chute;
    });

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Quem respondeu? 🕵️', style: TextStyle(fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Equipes'),
                          selected: _assignToTeam,
                          onSelected: (val) => setModalState(() => _assignToTeam = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Um Aluno'),
                          selected: !_assignToTeam,
                          onSelected: (val) => setModalState(() => _assignToTeam = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_assignToTeam)
                    DropdownButtonFormField<Team>(
                      value: _selectedTeam,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _teams.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                      onChanged: (val) => setState(() => _selectedTeam = val),
                    )
                  else
                    DropdownButtonFormField<Student>(
                      value: _selectedStudent,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _students.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                      onChanged: (val) => setState(() => _selectedStudent = val),
                    ),
                  const SizedBox(height: 24),
                  const Text('A resposta estava correta? 🤔', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _aplicarChuteAcerto();
                          },
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text('🟢 Sim', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _aplicarChuteErro();
                          },
                          icon: const Icon(Icons.close, color: Colors.white),
                          label: const Text('🔴 Não', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _aplicarChuteAcerto() async {
    // Add points automatically
    if (_assignToTeam && _selectedTeam != null) {
      if (_selectedTeam!.id != 0) {
        final db = await DatabaseHelper.instance.database;
        final updatedTeam = Team(
          id: _selectedTeam!.id,
          name: _selectedTeam!.name,
          color: _selectedTeam!.color,
          points: _selectedTeam!.points + 10,
        );
        await db.update('teams', updatedTeam.toMap(), where: 'id = ?', whereArgs: [updatedTeam.id]);
      }
    }
    
    setState(() {
      _fase = FaseJogo.resultado;
    });

    // Recompensa comemorativa imediata
    final vencedor = _assignToTeam ? (_selectedTeam?.name ?? '') : (_selectedStudent?.name ?? '');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            const Text('Parabéns!', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 24)),
            const SizedBox(height: 6),
            Text('$vencedor acertou!', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Fredoka', fontSize: 16, color: AppColors.verdePasto)),
            const Text('+10 pontos!', style: TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Era: ${_personagemAtual['nome']} ${_personagemAtual['emoji']}',
              style: const TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _personagemAtual['historia'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _sortearPersonagem();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulCeleste,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(180, 48),
              ),
              child: const Text('Continuar Jogando', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  void _aplicarChuteErro() {
    setState(() {
      _fase = FaseJogo.emAndamento;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('❌ Resposta Incorreta', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('Deseja continuar jogando para tentar novos chutes ou prefere revelar a resposta agora?'),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _iniciarTimer(_timeLeft); // Resumes timer
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulCeleste,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuar Cronômetro', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _fase = FaseJogo.finalizado;
              });
            },
            child: const Text('Revelar Resposta', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ],
      )
    );
  }

  Widget _buildFaseTracker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrackerItem('🟣', 'Preparando', _fase == FaseJogo.preparando),
          _buildTrackerItem('🟢', 'Andamento', _fase == FaseJogo.emAndamento),
          _buildTrackerItem('🟠', 'Chute', _fase == FaseJogo.chute),
          _buildTrackerItem('🔵', 'Resultado', _fase == FaseJogo.resultado || _fase == FaseJogo.finalizado),
        ],
      ),
    );
  }

  Widget _buildTrackerItem(String emoji, String text, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: active ? 1.0 : 0.25,
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 9,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? AppColors.textPrimary : AppColors.textSecondary.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Quem Sou Eu?', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              children: [
                // Phase Tracker
                _buildFaseTracker(),
                const SizedBox(height: 12),

                // Game Title Banner Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const MascotWidget(asset: MascotAssets.transparentSheep, width: 50, height: 50),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rodada $_rodadaAtual de $_totalRodadas',
                              style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.azulCeleste.withOpacity(0.9)),
                            ),
                            const Text(
                              'Quem Sou Eu? 🕵️',
                              style: TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const Text(
                              'Descubra o personagem antes dos seus amigos!',
                              style: TextStyle(fontFamily: 'Nunito', fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Toggle Modo (Segment Control style)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _modoMimica = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_modoMimica ? AppColors.azulCeleste : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '💡 Modo Dicas',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: !_modoMimica ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _modoMimica = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _modoMimica ? AppColors.roxoAcolhedor : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '🎭 Modo Mímica',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _modoMimica ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Mascot dialog hint
                Row(
                  children: [
                    const Text('🐑', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getMascotSpeech(),
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Game Body Content
                if (!_modoMimica) ...[
                  // --- DICAS MODE ---
                  ...List.generate(3, (index) {
                    final revelada = index < _dicasReveladas;
                    final isLocked = index > _dicasReveladas;
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: revelada ? Colors.white : (isLocked ? Colors.grey.shade100 : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: revelada ? AppColors.azulCeleste.withOpacity(0.5) : (isLocked ? Colors.grey.shade200 : AppColors.azulCeleste),
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          if (_dicasReveladas == index) {
                            setState(() => _dicasReveladas++);
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                height: 42,
                                width: 42,
                                decoration: BoxDecoration(
                                  color: revelada ? AppColors.azulCeleste.withOpacity(0.12) : Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  revelada ? Icons.lightbulb_outline_rounded : (isLocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded),
                                  color: revelada ? AppColors.azulCeleste : (isLocked ? Colors.grey.shade400 : AppColors.azulCeleste),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dica ${index + 1}',
                                      style: const TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      revelada 
                                          ? _personagemAtual['dicas'][index] 
                                          : (isLocked ? 'Bloqueada' : 'Toque para revelar a dica! 🔒'),
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 13,
                                        fontWeight: revelada ? FontWeight.bold : FontWeight.w500,
                                        color: revelada ? Color(0xFF1E293B) : Color(0xFF94A3B8),
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
                  }),
                ] else ...[
                  // --- MIMICA MODE ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_fase == FaseJogo.preparando) ...[
                          const Icon(Icons.visibility_off_outlined, size: 48, color: AppColors.roxoAcolhedor),
                          const SizedBox(height: 10),
                          const Text('Chame o ator à frente', style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: _showSecret,
                            icon: const Icon(Icons.visibility),
                            label: const Text('Ver Personagem (Em Segredo)', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.roxoAcolhedor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ] else ...[
                          // Duolingo Big Circular Timer
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                const Text('⏱️ TEMPO RESTANTE', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Text(
                                  _timeLeft == 0 ? '⏰ Tempo Esgotado!' : '$_timeLeft segundos',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: _timeLeft <= 10 ? AppColors.alerta : AppColors.azulCeleste,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_fase == FaseJogo.preparando) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(onPressed: () => setState(() => _timeLeft = 30), child: const Text('30s')),
                                const SizedBox(width: 8),
                                ElevatedButton(onPressed: () => setState(() => _timeLeft = 45), child: const Text('45s')),
                                const SizedBox(width: 8),
                                ElevatedButton(onPressed: () => setState(() => _timeLeft = 60), child: const Text('60s')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _iniciarTimer(_timeLeft),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Iniciar Cronômetro', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.verdePasto,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ] else if (_fase == FaseJogo.emAndamento) ...[
                            ElevatedButton.icon(
                              onPressed: _abrirPainelChute,
                              icon: const Icon(Icons.ads_click),
                              label: const Text('🎯 Arriscar Chute', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.laranjaCriativo,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ],
                        ]
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Answer Sheet / Score Control Card
                if (_fase == FaseJogo.finalizado || _fase == FaseJogo.resultado) ...[
                  // Premium Bible Character System card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.verdePasto, width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('🎉 A resposta correta era:', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          _personagemAtual['nome'],
                          style: const TextStyle(fontFamily: 'Fredoka', fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.verdePasto),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _personagemAtual['emoji'],
                          style: const TextStyle(fontSize: 36),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _personagemAtual['categoria'],
                            style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _personagemAtual['historia'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.azulCeleste),
                            const SizedBox(width: 6),
                            Text(
                              'Referência: ${_personagemAtual['referencia']}',
                              style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.azulCeleste),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _sortearPersonagem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulCeleste,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Próxima Rodada ➡️', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ] else ...[
                  // Bottom Buttons inside preparatory phases
                  if (!_modoMimica) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _abrirPainelChute,
                            icon: const Icon(Icons.stars),
                            label: const Text('Arriscar Chute', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.laranjaCriativo,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _dicasReveladas = 3;
                                _fase = FaseJogo.finalizado;
                              });
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('Revelar', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.roxoAcolhedor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMascotSpeech() {
    if (_fase == FaseJogo.resultado || _fase == FaseJogo.finalizado) return 'Gostou de conhecer o personagem? Vamos para o próximo!';
    if (_fase == FaseJogo.chute) return 'Quem será que vai pontuar agora?';
    if (_modoMimica) return 'O ator já pode ir à frente ver o segredo e imitar!';
    if (_dicasReveladas == 0) return 'Dica 1 pronta para ser revelada! Quem arrisca?';
    if (_dicasReveladas == 1) return 'Uma dica revelada! Querem a dica número 2?';
    return 'Última dica liberada! Quem sabe a resposta?';
  }

  void _showSecret() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🤫 Segredo do Ator', style: TextStyle(fontFamily: 'Fredoka', color: AppColors.roxoAcolhedor, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Você é:', style: TextStyle(fontFamily: 'Nunito', fontSize: 16, color: AppColors.textSecondary)),
            Text(_personagemAtual['nome'], style: const TextStyle(fontFamily: 'Fredoka', fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.roxoAcolhedor)),
            const SizedBox(height: 4),
            Text(_personagemAtual['emoji'], style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 20),
            const Text('Ideias para fazer mímica:', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...(_personagemAtual['dicas'] as List).map((dica) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.star, size: 16, color: AppColors.amareloSol),
                  const SizedBox(width: 8),
                  Expanded(child: Text(dica, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.bold))),
                ],
              ),
            )).toList(),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _fase = FaseJogo.preparando;
                  _timeLeft = 30; // Reset time
                });
                Navigator.pop(ctx);
                _iniciarTimer(30); // Auto-starts timer upon closing secret screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulCeleste,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(180, 44),
              ),
              child: const Text('Começar Mímica!', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
            ),
          )
        ],
      )
    );
  }
}
