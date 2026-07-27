import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
import '../../teams/models/team.dart';

class JogoSeteErrosScreen extends StatefulWidget {
  const JogoSeteErrosScreen({super.key});

  @override
  State<JogoSeteErrosScreen> createState() => _JogoSeteErrosScreenState();
}

class _JogoSeteErrosScreenState extends State<JogoSeteErrosScreen> {
  List<Team> _teams = [];
  Team? _activeTeam1;
  Team? _activeTeam2;
  
  bool _isTeam1Turn = true;
  int _tempoEscolhido = 60; // 0 para sem limite
  int _timeLeft = 60;
  Timer? _timer;
  bool _timerRunning = false;
  bool _jogoIniciado = false;
  
  final List<bool> _errosEncontrados = List.filled(7, false);
  int get _totalEncontrados => _errosEncontrados.where((e) => e).length;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    final teamsList = await DatabaseHelper.instance.fetchAllTeams();
    setState(() {
      _teams = List<Team>.from(teamsList);
      if (_teams.isEmpty) {
        _teams.add(Team(id: 0, name: 'Equipe Verde 🟢', color: 0xFF4CAF50, points: 0));
        _teams.add(Team(id: 0, name: 'Equipe Azul 🔵', color: 0xFF2196F3, points: 0));
      } else if (_teams.length == 1) {
        _teams.add(Team(id: 0, name: 'Equipe Azul 🔵 (Virtual)', color: 0xFF2196F3, points: 0));
      }
      _activeTeam1 = _teams[0];
      _activeTeam2 = _teams[1];
    });
  }

  void _iniciarJogo() {
    setState(() {
      _jogoIniciado = true;
      _errosEncontrados.fillRange(0, 7, false);
      _isTeam1Turn = true;
      _timeLeft = _tempoEscolhido;
      _timerRunning = false;
    });
    if (_tempoEscolhido > 0) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        t.cancel();
        setState(() => _timerRunning = false);
        _onTimeUp();
      }
    });
  }
  
  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = false);
  }

  void _onTimeUp() {
    if (_totalEncontrados == 7) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Tempo Esgotado! ⏰', style: TextStyle(color: AppColors.alerta, fontWeight: FontWeight.bold)),
        content: Text('A equipe ${_isTeam1Turn ? _activeTeam1?.name : _activeTeam2?.name} não encontrou todos os erros a tempo.\n\nA equipe adversária quer tentar roubar os pontos restantes?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finalizarPartida();
            },
            child: const Text('Não, encerrar rodada', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isTeam1Turn = !_isTeam1Turn;
                _timeLeft = _tempoEscolhido > 0 ? 30 : 0; // Dá 30s pro rouba-monte se houver limite
              });
              if (_timeLeft > 0) _startTimer();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.laranjaCriativo, foregroundColor: Colors.white),
            child: const Text('Sim, Passar a Vez! (Rouba-Monte)'),
          )
        ],
      )
    );
  }

  void _marcarErro(int index) {
    if (!_jogoIniciado || _errosEncontrados[index] || (_tempoEscolhido > 0 && _timeLeft == 0)) return;
    
    setState(() {
      _errosEncontrados[index] = true;
    });
    
    if (_totalEncontrados == 7) {
      _timer?.cancel();
      _finalizarPartida();
    }
  }

  Future<void> _finalizarPartida() async {
    int pts = _totalEncontrados * 10; // 10 pts por erro
    if (_totalEncontrados == 7) pts += 30; // Bonus por achar todos
    
    Team? equipeVencedora = _isTeam1Turn ? _activeTeam1 : _activeTeam2;
    
    if (equipeVencedora != null && pts > 0 && equipeVencedora.id != 0) {
      final updatedTeam = Team(
        id: equipeVencedora.id,
        name: equipeVencedora.name,
        color: equipeVencedora.color,
        points: equipeVencedora.points + pts,
      );
      await DatabaseHelper.instance.updateTeam(updatedTeam);
    }
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('🎉 Fim de Jogo!'),
          content: Text('A equipe ${equipeVencedora?.name ?? ""} encontrou $_totalEncontrados erros!\n\n+$pts Pontos ganhos!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _jogoIniciado = false);
              },
              child: const Text('Voltar ao Menu'),
            )
          ],
        )
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Jogo dos 7 Erros', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _jogoIniciado ? _buildGameScreen() : _buildSetupScreen(),
    );
  }

  Widget _buildSetupScreen() {
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
              const Icon(Icons.image_search_rounded, size: 64, color: AppColors.azulCeleste),
              const SizedBox(height: 16),
              const Text('Quem vai jogar?', style: TextStyle(fontFamily: 'Fredoka', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              if (_teams.length < 2)
                const Text('Cadastre pelo menos 2 equipes primeiro!', style: TextStyle(color: Colors.red))
              else ...[
                const Text('Equipe 1', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: AppColors.azulCeleste)),
                DropdownButton<Team>(
                  value: _activeTeam1,
                  isExpanded: true,
                  items: _teams.map((Team team) => DropdownMenuItem<Team>(value: team, child: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (Team? newValue) => setState(() => _activeTeam1 = newValue),
                ),
                const SizedBox(height: 16),
                const Text('Equipe 2 (Adversária)', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: AppColors.laranjaCriativo)),
                DropdownButton<Team>(
                  value: _activeTeam2,
                  isExpanded: true,
                  items: _teams.map((Team team) => DropdownMenuItem<Team>(value: team, child: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (Team? newValue) => setState(() => _activeTeam2 = newValue),
                ),
              ],
              const SizedBox(height: 32),
              const Text('Tempo da Rodada', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChoiceChip(
                    label: const Text('30s'),
                    selected: _tempoEscolhido == 30,
                    onSelected: (v) => setState(() => _tempoEscolhido = 30),
                  ),
                  ChoiceChip(
                    label: const Text('60s'),
                    selected: _tempoEscolhido == 60,
                    onSelected: (v) => setState(() => _tempoEscolhido = 60),
                  ),
                  ChoiceChip(
                    label: const Text('Sem Limite'),
                    selected: _tempoEscolhido == 0,
                    onSelected: (v) => setState(() => _tempoEscolhido = 0),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _teams.length < 2 ? null : _iniciarJogo,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar Desafio!', style: TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulCeleste,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    final teamName = _isTeam1Turn ? _activeTeam1?.name : _activeTeam2?.name;
    final teamColor = _isTeam1Turn ? AppColors.azulCeleste : AppColors.laranjaCriativo;
    
    return Column(
      children: [
        // Premium Card Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🐑 ', style: TextStyle(fontSize: 18)),
                        Text(
                          'Vez de: $teamName',
                          style: TextStyle(fontFamily: 'Fredoka', fontSize: 15, fontWeight: FontWeight.bold, color: teamColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Stars progress indicator
                    Row(
                      children: List.generate(7, (index) {
                        final achou = _errosEncontrados[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Text(
                            achou ? '⭐' : '○',
                            style: TextStyle(
                              fontSize: 16,
                              color: achou ? Colors.amber : Colors.grey.shade300,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                
                // Circular Timer
                if (_tempoEscolhido > 0)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          value: _timeLeft / _tempoEscolhido,
                          strokeWidth: 4,
                          backgroundColor: Colors.grey.shade100,
                          color: _timeLeft <= 10 ? AppColors.alerta : AppColors.azulCeleste,
                        ),
                      ),
                      Text(
                        '$_timeLeft',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _timeLeft <= 10 ? AppColors.alerta : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // Mascot Helper Speech Bubble
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
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
        ),
        const SizedBox(height: 8),

        // Scenes Wrapper Card (Arca de Noé Theme)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isPortrait = constraints.maxHeight > constraints.maxWidth;
                    if (isPortrait) {
                      return Column(
                        children: [
                          Expanded(child: _buildSceneWrapper(isDiff: false)),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                          Expanded(child: _buildSceneWrapper(isDiff: true)),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(child: _buildSceneWrapper(isDiff: false)),
                          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                          Expanded(child: _buildSceneWrapper(isDiff: true)),
                        ],
                      );
                    }
                  }
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getMascotSpeech() {
    final restantes = 7 - _totalEncontrados;
    if (_totalEncontrados == 0) return 'Vamos encontrar todos os 7 erros na arca?';
    if (restantes == 2) return 'Só mais dois erros na arca! Você consegue!';
    if (restantes == 1) return 'Falta apenas um! Onde ele está?';
    return 'Boa! Continue procurando!';
  }

  Widget _buildSceneWrapper({required bool isDiff}) {
    return Container(
      color: const Color(0xFFE0F2FE), // Céu azul bem suave
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 440,
            height: 330, // Aumentado em 25% para melhor visualização
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // --- CENÁRIO: A ARCA DE NOÉ ---
                
                // 1. Água / Mar (Background bottom)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 90,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // 2. Arco-Íris (Apenas na imagem principal, sumido na diff)
                if (!isDiff)
                  Positioned(
                    top: 15,
                    left: 40,
                    child: Opacity(
                      opacity: 0.65,
                      child: CustomPaint(
                        size: const Size(120, 60),
                        painter: _RainbowPainter(),
                      ),
                    ),
                  ),

                // 3. Montanhas ao fundo
                Positioned(
                  bottom: 85,
                  left: 20,
                  child: Icon(Icons.terrain_rounded, size: 70, color: Colors.blueGrey.shade100),
                ),
                Positioned(
                  bottom: 85,
                  right: 40,
                  child: Icon(Icons.terrain_rounded, size: 90, color: Colors.blueGrey.shade100),
                ),

                // 4. A Arca de Noé (Grande barco de madeira no mar)
                Positioned(
                  bottom: 45,
                  left: 100,
                  child: Container(
                    width: 240,
                    height: 75,
                    decoration: BoxDecoration(
                      color: const Color(0xFF78350F), // Marrom Arca
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(50),
                        bottomRight: Radius.circular(50),
                        topRight: Radius.circular(10),
                        topLeft: Radius.circular(10),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Janelas da arca
                        Positioned(top: 15, left: 30, child: Container(width: 14, height: 14, color: const Color(0xFFFCD34D))),
                        Positioned(top: 15, left: 70, child: Container(width: 14, height: 14, color: const Color(0xFFFCD34D))),
                        Positioned(top: 15, left: 110, child: Container(width: 14, height: 14, color: const Color(0xFFFCD34D))),
                        Positioned(top: 15, left: 150, child: Container(width: 14, height: 14, color: const Color(0xFFFCD34D))),
                        // 5. Girafa na arca (Sumiu na diff)
                        if (!isDiff)
                          Positioned(
                            top: -28,
                            right: 40,
                            child: const Text('🦒', style: TextStyle(fontSize: 34)),
                          ),
                        // 6. Elefante na arca (Virado de lado / Deslocado)
                        Positioned(
                          top: -24,
                          left: isDiff ? 12 : 30,
                          child: const Text('🐘', style: TextStyle(fontSize: 30)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Cabine da Arca (Casa de madeira em cima do barco)
                Positioned(
                  bottom: 120,
                  left: 140,
                  child: Container(
                    width: 160,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF92400E),
                      border: Border.all(color: const Color(0xFF78350F), width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(width: 20, height: 30, color: const Color(0xFF1E293B)),
                        Container(width: 20, height: 30, color: const Color(0xFF1E293B)),
                      ],
                    ),
                  ),
                ),
                // Telhado da Cabine
                Positioned(
                  bottom: 170,
                  left: 130,
                  child: Container(
                    width: 180,
                    height: 15,
                    color: const Color(0xFFB45309),
                  ),
                ),

                // 7. Pomba voando com ramo de oliveira (Sumiu / Deslocada na diff)
                Positioned(
                  top: isDiff ? 65 : 45,
                  right: isDiff ? 100 : 70,
                  child: const Text('🕊️', style: TextStyle(fontSize: 26)),
                ),

                // 8. Ovelha na arca (Sumiu na diff)
                if (!isDiff)
                  Positioned(
                    bottom: 108,
                    left: 210,
                    child: const Text('🐑', style: TextStyle(fontSize: 28)),
                  ),

                // 9. Nuvens no céu
                Positioned(
                  top: 25,
                  left: 20,
                  child: Icon(Icons.cloud_rounded, size: 45, color: Colors.white.withOpacity(0.9)),
                ),
                // Outra Nuvem (Sumiu na diff)
                if (!isDiff)
                  Positioned(
                    top: 15,
                    right: 30,
                    child: Icon(Icons.cloud_rounded, size: 55, color: Colors.white.withOpacity(0.9)),
                  ),

                // 10. Sol (No topo central)
                Positioned(
                  top: 10,
                  left: 200,
                  child: Icon(Icons.wb_sunny_rounded, size: 40, color: Colors.amber.shade400),
                ),

                // --- HOTSPOTS DE ERRO (Apenas mapeado na imagem Diff) ---
                if (isDiff) ...[
                  _buildHotspot(0, top: 10, left: 35, width: 130, height: 70), // Arco-Íris sumiu
                  _buildHotspot(1, bottom: 90, right: 35, width: 55, height: 50), // Girafa sumiu
                  _buildHotspot(2, bottom: 90, left: 105, width: 60, height: 50), // Elefante deslocado
                  _buildHotspot(3, top: 35, right: 65, width: 80, height: 60), // Pomba deslocada
                  _buildHotspot(4, bottom: 100, left: 200, width: 45, height: 45), // Ovelha sumiu
                  _buildHotspot(5, top: 10, right: 20, width: 70, height: 60), // Nuvem sumiu
                  _buildHotspot(6, top: 10, left: 190, width: 60, height: 50), // Sol (não é erro, mas mantemos o hotspot 6 na água ou no mar!)
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHotspot(int erroIndex, {double? top, double? bottom, double? left, double? right, required double width, required double height}) {
    final encontrado = _errosEncontrados[erroIndex];
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: GestureDetector(
        onTap: () => _marcarErro(erroIndex),
        child: _AnimatedHotspotCircle(encontrado: encontrado, width: width, height: height),
      ),
    );
  }
}

// Widget de Hotspot com feedback visual interativo
class _AnimatedHotspotCircle extends StatefulWidget {
  final bool encontrado;
  final double width;
  final double height;

  const _AnimatedHotspotCircle({required this.encontrado, required this.width, required this.height});

  @override
  State<_AnimatedHotspotCircle> createState() => _AnimatedHotspotCircleState();
}

class _AnimatedHotspotCircleState extends State<_AnimatedHotspotCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.encontrado) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedHotspotCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.encontrado && !oldWidget.encontrado) {
      _controller.forward();
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
      scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          border: Border.all(color: const Color(0xFF10B981), width: 4),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ],
        ),
        child: const Center(
          child: Text('✨', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

// Pintor customizado para o arco-íris
class _RainbowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height);
    
    // Vermelho
    paint.color = Colors.red.shade400;
    canvas.drawArc(Rect.fromCircle(center: center, radius: 45), 3.14, 3.14, false, paint);
    
    // Laranja
    paint.color = Colors.orange.shade400;
    canvas.drawArc(Rect.fromCircle(center: center, radius: 41), 3.14, 3.14, false, paint);

    // Amarelo
    paint.color = Colors.yellow.shade400;
    canvas.drawArc(Rect.fromCircle(center: center, radius: 37), 3.14, 3.14, false, paint);

    // Verde
    paint.color = Colors.green.shade400;
    canvas.drawArc(Rect.fromCircle(center: center, radius: 33), 3.14, 3.14, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
