import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
import '../../teams/models/team.dart';
import '../../../core/components/mascot/mascot_widget.dart';

class JogoMemoriaIcon {
  final IconData iconData;
  final Color color;

  const JogoMemoriaIcon(this.iconData, this.color);
}

class JogoMemoriaScreen extends StatefulWidget {
  const JogoMemoriaScreen({super.key});

  @override
  State<JogoMemoriaScreen> createState() => _JogoMemoriaScreenState();
}

class _JogoMemoriaScreenState extends State<JogoMemoriaScreen> {
  List<Team> _teams = [];
  Team? _activeTeam1;
  Team? _activeTeam2;
  bool _isTeamVsTeam = true;
  
  bool _jogoIniciado = false;
  int _paresEquipe1 = 0;
  int _paresEquipe2 = 0;

  Timer? _gameTimer;
  int _segundosGastos = 0;

  // Bible Card System Illustration Icons
  final List<JogoMemoriaIcon> _ilustracoesBiblicas = [
    const JogoMemoriaIcon(Icons.menu_book_rounded, Color(0xFF1E3A8A)), // Bible
    const JogoMemoriaIcon(Icons.sailing_rounded, Color(0xFFB45309)), // Noah's Ark
    const JogoMemoriaIcon(Icons.favorite_rounded, Color(0xFFBE185D)), // Love
    const JogoMemoriaIcon(Icons.emoji_events_rounded, Color(0xFFF59E0B)), // Crown
    const JogoMemoriaIcon(Icons.pets_rounded, Color(0xFF047857)), // Lion
    const JogoMemoriaIcon(Icons.wb_sunny_rounded, Color(0xFFEAB308)), // Star
    const JogoMemoriaIcon(Icons.church_rounded, Color(0xFF6D28D9)), // Church
    const JogoMemoriaIcon(Icons.local_fire_department_rounded, Color(0xFFDC2626)), // Holy Spirit
    const JogoMemoriaIcon(Icons.water_drop_rounded, Color(0xFF0284C7)), // Water
    const JogoMemoriaIcon(Icons.lightbulb_rounded, Color(0xFFD97706)), // Light
    const JogoMemoriaIcon(Icons.music_note_rounded, Color(0xFF4F46E5)), // Music
    const JogoMemoriaIcon(Icons.key_rounded, Color(0xFF475569)), // Key
  ];

  List<JogoMemoriaIcon> _activeIlustracoes = [];
  late List<JogoMemoriaIcon> _cartas;
  List<bool> _reveladas = [];
  List<bool> _encontradas = [];
  
  int? _primeiraCartaIndex;
  bool _esperando = false;
  int _paresEncontrados = 0;
  
  bool _isTeam1Turn = true;

  @override
  void initState() {
    super.initState();
    _activeIlustracoes = List.from(_ilustracoesBiblicas);
    _loadTeams();
    _loadActiveLessonPlan();
  }

  Future<void> _loadActiveLessonPlan() async {
    final plan = await DatabaseHelper.instance.fetchLessonOfTheWeek();
    if (plan != null) {
      final text = '${plan.title} ${plan.storyTopics} ${plan.objective}'.toLowerCase();
      
      final scores = <JogoMemoriaIcon, int>{};
      for (final icon in _ilustracoesBiblicas) {
        int score = 0;
        if (icon.iconData == Icons.sailing_rounded && (text.contains('barco') || text.contains('mar') || text.contains('tempestade') || text.contains('noé') || text.contains('jonas') || text.contains('pescador') || text.contains('peixe'))) {
          score += 10;
        }
        if (icon.iconData == Icons.water_drop_rounded && (text.contains('água') || text.contains('mar') || text.contains('rio') || text.contains('chuva') || text.contains('dilúvio'))) {
          score += 10;
        }
        if (icon.iconData == Icons.pets_rounded && (text.contains('leão') || text.contains('animais') || text.contains('arca') || text.contains('daniel'))) {
          score += 10;
        }
        if (icon.iconData == Icons.local_fire_department_rounded && (text.contains('fogo') || text.contains('sarça') || text.contains('espírito') || text.contains('poder'))) {
          score += 10;
        }
        if (icon.iconData == Icons.favorite_rounded && (text.contains('amor') || text.contains('coração') || text.contains('amar') || text.contains('deus'))) {
          score += 5;
        }
        if (icon.iconData == Icons.emoji_events_rounded && (text.contains('rei') || text.contains('davi') || text.contains('coroa') || text.contains('vitória') || text.contains('golias'))) {
          score += 10;
        }
        if (icon.iconData == Icons.music_note_rounded && (text.contains('música') || text.contains('louvor') || text.contains('harpa') || text.contains('cantar'))) {
          score += 10;
        }
        if (icon.iconData == Icons.wb_sunny_rounded && (text.contains('sol') || text.contains('estrela') || text.contains('dia') || text.contains('luz') || text.contains('criação'))) {
          score += 10;
        }
        scores[icon] = score;
      }
      
      final sorted = List<JogoMemoriaIcon>.from(_ilustracoesBiblicas);
      sorted.sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));
      
      setState(() {
        _activeIlustracoes = sorted;
      });
    }
  }

  Future<void> _loadTeams() async {
    setState(() {
      _teams = [
        Team(id: 1, name: 'Grupo A 🔵', color: 0xFF2196F3, points: 0),
        Team(id: 2, name: 'Grupo B 🟡', color: 0xFFFFB300, points: 0),
      ];
      _activeTeam1 = _teams[0];
      _activeTeam2 = _teams[1];
    });
  }

  void _prepararCartas() {
    int numPares = 12;
    int numCartas = numPares * 2;
    
    List<JogoMemoriaIcon> ilustracoesSelecionadas = _activeIlustracoes.take(numPares).toList();
    _cartas = [...ilustracoesSelecionadas, ...ilustracoesSelecionadas];
    _cartas.shuffle();
    _reveladas = List.filled(numCartas, false);
    _encontradas = List.filled(numCartas, false);
    _primeiraCartaIndex = null;
    _esperando = false;
    _paresEncontrados = 0;
    _paresEquipe1 = 0;
    _paresEquipe2 = 0;
    _isTeam1Turn = true;
    _segundosGastos = 0;
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _segundosGastos++);
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
  
  void _iniciarJogo() {
    setState(() {
      _jogoIniciado = true;
      _prepararCartas();
    });
  }

  void _onCartaTap(int index) {
    if (_esperando || _reveladas[index] || _encontradas[index]) return;

    setState(() {
      _reveladas[index] = true;
    });

    if (_primeiraCartaIndex == null) {
      _primeiraCartaIndex = index;
    } else {
      _esperando = true;
      if (_cartas[_primeiraCartaIndex!].iconData == _cartas[index].iconData) {
        setState(() {
          _encontradas[_primeiraCartaIndex!] = true;
          _encontradas[index] = true;
          _paresEncontrados++;
          
          if (_isTeam1Turn) _paresEquipe1++;
          else _paresEquipe2++;

          _esperando = false;
          _primeiraCartaIndex = null;
        });

        if (_paresEncontrados == 12) {
          _finalizarJogo();
        }
      } else {
        Timer(const Duration(seconds: 1), () {
          if (!mounted) return;
          setState(() {
            if (_primeiraCartaIndex != null) {
              _reveladas[_primeiraCartaIndex!] = false;
            }
            _reveladas[index] = false;
            _esperando = false;
            _primeiraCartaIndex = null;
            
            if (_activeTeam2 != null) {
              _isTeam1Turn = !_isTeam1Turn;
            }
          });
        });
      }
    }
  }

  int _calcularPontosDesafio(int tempoEmSegundos) {
    const int pontosMaximos = 50;
    const int pontosMinimos = 10;
    
    if (tempoEmSegundos <= 40) return pontosMaximos;

    int tempoExcedente = tempoEmSegundos - 40;
    int penalidade = (tempoExcedente / 10).ceil() * 10;

    int pontuacaoFinal = pontosMaximos - penalidade;
    return pontuacaoFinal < pontosMinimos ? pontosMinimos : pontuacaoFinal;
  }

  Future<void> _finalizarJogo() async {
    _gameTimer?.cancel();
    
    String msg = '';
    
    if (_activeTeam1 != null && _activeTeam2 != null && _isTeamVsTeam) {
      if (_paresEquipe1 > _paresEquipe2) {
        msg = 'Vencedor: ${_activeTeam1!.name}! (+50 pts)';
        await _addPoints(_activeTeam1!, 50);
      } else if (_paresEquipe2 > _paresEquipe1) {
        msg = 'Vencedor: ${_activeTeam2!.name}! (+50 pts)';
        await _addPoints(_activeTeam2!, 50);
      } else {
        msg = 'Empate técnico! Ambas equipes jogaram muito bem! (+25 pts)';
        await _addPoints(_activeTeam1!, 25);
        await _addPoints(_activeTeam2!, 25);
      }
    } else if (_activeTeam1 != null) {
      final pts = _calcularPontosDesafio(_segundosGastos);
      msg = 'Você concluiu o desafio da memória em $_segundosGastos segundos!\n\n+$pts Pontos ganhos para ${_activeTeam1!.name}!';
      await _addPoints(_activeTeam1!, pts);
    }
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Column(
            children: [
              Text('🎉', style: TextStyle(fontSize: 48)),
              SizedBox(height: 10),
              Text('Parabéns!', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 24)),
              Text('Você encontrou todos!', style: TextStyle(fontFamily: 'Nunito', fontSize: 16, color: AppColors.textSecondary)),
            ],
          ),
          content: Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.bold)),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _jogoIniciado = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulCeleste,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(180, 48),
              ),
              child: const Text('Voltar ao Menu', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
            )
          ],
        )
      );
    }
  }

  Future<void> _addPoints(Team team, int pts) async {
    if (team.id == 0) return;
    final updated = Team(
      id: team.id, 
      name: team.name, 
      color: team.color, 
      points: team.points + pts
    );
    await DatabaseHelper.instance.updateTeam(updated);
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regras do Jogo 🧩', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
        content: const Text(
          '1. Escolha o modo Equipes ou Solo contra o tempo.\n'
          '2. Toque em duas cartas para virá-las.\n'
          '3. Se acertar o par, a equipe pontua e continua jogando. Se errar, passa a vez.\n'
          '4. Quem achar mais pares vence e leva os pontos!'
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
        title: const Text('Jogo da Memória', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
      body: _jogoIniciado ? _buildTabuleiro() : _buildSetup(),
    );
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
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.grid_view_rounded, size: 64, color: AppColors.verdePasto),
              const SizedBox(height: 16),
              const Text('Modo de Jogo', style: TextStyle(fontFamily: 'Fredoka', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Modo 1: Equipe vs Equipe'),
                    selected: _isTeamVsTeam,
                    onSelected: (v) => setState(() => _isTeamVsTeam = true),
                  ),
                  ChoiceChip(
                    label: const Text('Modo 2: Contra o Tempo'),
                    selected: !_isTeamVsTeam,
                    onSelected: (v) => setState(() => _isTeamVsTeam = false),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Quem vai jogar?', style: TextStyle(fontFamily: 'Fredoka', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              if (_teams.isEmpty)
                const Text('Cadastre pelo menos 1 equipe primeiro!', style: TextStyle(color: Colors.red))
              else if (_isTeamVsTeam && _teams.length < 2)
                const Text('Cadastre pelo menos 2 equipes para o modo Vs!', style: TextStyle(color: Colors.red))
              else ...[
                const Text('Equipe 1', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: AppColors.azulCeleste)),
                DropdownButton<Team>(
                  value: _activeTeam1,
                  isExpanded: true,
                  items: _teams.map((Team team) => DropdownMenuItem<Team>(value: team, child: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (Team? newValue) => setState(() => _activeTeam1 = newValue),
                ),
                if (_isTeamVsTeam) ...[
                  const SizedBox(height: 16),
                  const Text('Equipe 2', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: AppColors.laranjaCriativo)),
                  DropdownButton<Team>(
                    value: _activeTeam2,
                    isExpanded: true,
                    items: _teams.map((Team team) => DropdownMenuItem<Team>(value: team, child: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (Team? newValue) => setState(() => _activeTeam2 = newValue),
                  ),
                ],
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _iniciarJogo,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar Jogo!', style: TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdePasto,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabuleiro() {
    final activeColor = _isTeam1Turn ? AppColors.azulCeleste : AppColors.laranjaCriativo;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcule o espaço disponível dinamicamente
        final headerHeight = 72.0; // Altura aproximada do placar de cima
        final tipsHeight = 48.0;   // Altura aproximada da dica da ovelha
        final paddingVertical = 16.0;
        final availableHeight = constraints.maxHeight - headerHeight - tipsHeight - paddingVertical;
        
        // Tabuleiro dinâmico proporcional à área restante da tela
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Column(
            children: [
              // 1. Cabeçalho / Placar compacto
              SizedBox(
                height: headerHeight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_isTeamVsTeam) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(_isTeam1Turn ? '🔵 ' : '🟠 '),
                                Text(
                                  _isTeam1Turn ? 'Equipe Azul' : 'Equipe Laranja',
                                  style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold, color: activeColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isTeam1Turn ? 'Pares: $_paresEquipe1 / 12' : 'Pares: $_paresEquipe2 / 12',
                              style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ] else ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Desafio Solo',
                              style: TextStyle(fontFamily: 'Fredoka', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.verdePasto),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pares: $_paresEncontrados de 12',
                              style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200, width: 1),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                value: (_segundosGastos % 60) / 60,
                                strokeWidth: 2.5,
                                backgroundColor: Colors.grey.shade200,
                                color: AppColors.azulCeleste,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_segundosGastos}s',
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 3. Tabuleiro dimensionado dinamicamente com base na altura restante
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(), // Mantém fixo na tela
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 1.15, // Aumenta a proporção para deixar os cards mais baixos (menos cumpridos)
                    ),
                    itemCount: _cartas.length,
                    itemBuilder: (context, index) {
                      final revelada = _reveladas[index];
                      final encontrada = _encontradas[index];
                      
                      return _MemoryCardWidget(
                        illustration: _cartas[index],
                        revelada: revelada,
                        encontrada: encontrada,
                        onTap: () => _onCartaTap(index),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMascotSpeech() {
    if (_paresEncontrados == 0) return 'Toque nas cartas para encontrar os pares bíblicos!';
    if (_paresEncontrados == 11) return 'Falta apenas um par! Você consegue!';
    return 'Boa! Já encontramos $_paresEncontrados pares!';
  }
}

class _MemoryCardWidget extends StatefulWidget {
  final JogoMemoriaIcon illustration;
  final bool revelada;
  final bool encontrada;
  final VoidCallback onTap;

  const _MemoryCardWidget({
    required this.illustration,
    required this.revelada,
    required this.encontrada,
    required this.onTap,
  });

  @override
  State<_MemoryCardWidget> createState() => _MemoryCardWidgetState();
}

class _MemoryCardWidgetState extends State<_MemoryCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.revelada || widget.encontrada) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _MemoryCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final virada = widget.revelada || widget.encontrada;
    final oldVirada = oldWidget.revelada || oldWidget.encontrada;
    if (virada != oldVirada) {
      if (virada) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * 3.14159265;
        final isFront = angle >= 3.14159265 / 2;
        
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: widget.onTap,
            child: isFront
                ? Transform(
                    transform: Matrix4.identity()..rotateY(3.14159265),
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.encontrada ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          widget.illustration.iconData,
                          color: widget.illustration.color,
                          size: 38,
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: MascotWidget(
                        pose: MascotPose.idle,
                        width: 54,
                        height: 54,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
