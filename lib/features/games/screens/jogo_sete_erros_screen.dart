import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/db/database_helper.dart';
import '../../teams/models/team.dart';
import '../../../core/components/mascot/mascot_widget.dart';
import '../../../core/components/mascot/mascot_assets.dart';
import '../../../core/design_system/colors.dart';

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

  // Variável para feedback de erro incorreto temporário
  Offset? _feedbackIncorretoPos;

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

  void _onTimeUp() {
    if (_totalEncontrados == 7) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tempo Esgotado! ⏰',
                  style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFEF4444)),
                ),
                const SizedBox(height: 12),
                Text(
                  'A equipe ${_isTeam1Turn ? _activeTeam1?.name : _activeTeam2?.name} não encontrou todos os erros a tempo.\n\nA equipe adversária quer tentar roubar os pontos restantes?',
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _finalizarPartida();
                      },
                      child: const Text('Não, encerrar', style: TextStyle(fontFamily: 'Fredoka', color: Color(0xFF64748B))),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _isTeam1Turn = !_isTeam1Turn;
                          _timeLeft = _tempoEscolhido > 0 ? 30 : 0;
                        });
                        if (_timeLeft > 0) _startTimer();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DsColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Sim, Passar a Vez! ➔', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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

  void _registrarToqueIncorreto(Offset posLocal) {
    setState(() {
      _feedbackIncorretoPos = posLocal;
    });
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _feedbackIncorretoPos = null;
        });
      }
    });
  }

  Future<void> _finalizarPartida() async {
    int pts = _totalEncontrados * 10;
    if (_totalEncontrados == 7) pts += 30;
    
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
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '🎉 Fim do Jogo!',
                    style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A equipe ${equipeVencedora?.name ?? ""} encontrou $_totalEncontrados erros!\n\n+$pts Pontos acumulados! ⭐',
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _jogoIniciado = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DsColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Voltar ao Menu', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
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
      backgroundColor: const Color(0xFFF8FAFC),
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
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: Icon(Icons.image_search_rounded, size: 64, color: DsColors.primaryBlue)),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Quem vai jogar?',
                  style: TextStyle(fontFamily: 'Fredoka', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(height: 24),
              if (_teams.length < 2)
                const Text('Cadastre pelo menos 2 equipes primeiro!', style: TextStyle(color: Colors.red, fontFamily: 'Nunito'))
              else ...[
                const Text('Equipe 1', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 13, color: DsColors.primaryBlue)),
                const SizedBox(height: 6),
                DropdownButtonFormField<Team>(
                  value: _activeTeam1,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                  items: _teams.map((Team team) => DropdownMenuItem<Team>(value: team, child: Text(team.name, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (Team? newValue) => setState(() => _activeTeam1 = newValue),
                ),
                const SizedBox(height: 16),
                const Text('Equipe 2 (Adversária)', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.laranjaCriativo)),
                const SizedBox(height: 6),
                DropdownButtonFormField<Team>(
                  value: _activeTeam2,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                  items: _teams.map((Team team) => DropdownMenuItem<Team>(value: team, child: Text(team.name, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (Team? newValue) => setState(() => _activeTeam2 = newValue),
                ),
              ],
              const SizedBox(height: 24),
              const Text('Tempo da Rodada', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChoiceChip(
                    label: const Text('30s', style: TextStyle(fontFamily: 'Fredoka')),
                    selected: _tempoEscolhido == 30,
                    selectedColor: DsColors.primaryBlue.withOpacity(0.15),
                    labelStyle: TextStyle(color: _tempoEscolhido == 30 ? DsColors.primaryBlue : Color(0xFF64748B), fontWeight: FontWeight.bold),
                    onSelected: (v) => setState(() => _tempoEscolhido = 30),
                  ),
                  ChoiceChip(
                    label: const Text('60s', style: TextStyle(fontFamily: 'Fredoka')),
                    selected: _tempoEscolhido == 60,
                    selectedColor: DsColors.primaryBlue.withOpacity(0.15),
                    labelStyle: TextStyle(color: _tempoEscolhido == 60 ? DsColors.primaryBlue : Color(0xFF64748B), fontWeight: FontWeight.bold),
                    onSelected: (v) => setState(() => _tempoEscolhido = 60),
                  ),
                  ChoiceChip(
                    label: const Text('Sem Limite', style: TextStyle(fontFamily: 'Fredoka')),
                    selected: _tempoEscolhido == 0,
                    selectedColor: DsColors.primaryBlue.withOpacity(0.15),
                    labelStyle: TextStyle(color: _tempoEscolhido == 0 ? DsColors.primaryBlue : Color(0xFF64748B), fontWeight: FontWeight.bold),
                    onSelected: (v) => setState(() => _tempoEscolhido = 0),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _teams.length < 2 ? null : _iniciarJogo,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Iniciar Desafio!', style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DsColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
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
    final teamColor = _isTeam1Turn ? DsColors.primaryBlue : AppColors.laranjaCriativo;
    final timerNearEnd = _timeLeft <= 10;
    
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
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10),
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
                    const SizedBox(height: 8),
                    // Checkmarks / Dots Progress indicator
                    Row(
                      children: List.generate(7, (index) {
                        final achou = _errosEncontrados[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Icon(
                            achou ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                            size: 18,
                            color: achou ? Colors.green : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                
                // Circular Timer
                if (_tempoEscolhido > 0)
                  AnimatedScale(
                    scale: timerNearEnd ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            value: _timeLeft / _tempoEscolhido,
                            strokeWidth: 4.5,
                            backgroundColor: Colors.grey.shade100,
                            color: timerNearEnd ? const Color(0xFFEF4444) : DsColors.primaryBlue,
                          ),
                        ),
                        Text(
                          '$_timeLeft',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: timerNearEnd ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
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
              const MascotWidget(pose: MascotPose.front, width: 38, height: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.1)),
                  ),
                  child: Text(
                    _getMascotSpeech(),
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Scenes Wrapper Card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Card(
              color: Colors.white,
              elevation: 2,
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
    if (_totalEncontrados == 0) return 'Toque na imagem da direita onde encontrar um erro! Temos 7 erros escondidos na Arca de Noé!';
    if (restantes == 2) return 'Quase lá! Só faltam mais 2 erros na arca!';
    if (restantes == 1) return 'Último erro! Procure com bastante atenção!';
    return 'Excelente! Continue assim, equipe!';
  }

  Widget _buildSceneWrapper({required bool isDiff}) {
    return Container(
      color: const Color(0xFFE0F2FE),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: GestureDetector(
            onTapDown: (details) {
              if (isDiff) {
                _registrarToqueIncorreto(details.localPosition);
              }
            },
            child: SizedBox(
              width: 440,
              height: 330,
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

                  // 2. Arco-Íris
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

                  // 4. A Arca de Noé
                  Positioned(
                    bottom: 45,
                    left: 100,
                    child: Container(
                      width: 240,
                      height: 75,
                      decoration: BoxDecoration(
                        color: const Color(0xFF78350F),
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
                          Positioned(top: 15, left: 30, child: Container(width: 14, height: 14, color: const Color(0xFFFCD34D))),
                          Positioned(top: 15, left: 70, child: Container(width: 14, height: 14, color: const Color(0xFFFCD34D))),
                          Positioned(top: 15, left: 110, child: Container(width: 14, height: 14, color: const Color(0xFFFCD34D))),
                          Positioned(top: 15, left: 150, child: Container(width: 14, height: 14, color: const Color(0xFFFCD34D))),
                          if (!isDiff)
                            Positioned(
                              top: -28,
                              right: 40,
                              child: const Text('🦒', style: TextStyle(fontSize: 34)),
                            ),
                          Positioned(
                            top: -24,
                            left: isDiff ? 12 : 30,
                            child: const Text('🐘', style: TextStyle(fontSize: 30)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Cabine da Arca
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

                  // 7. Pomba voando
                  Positioned(
                    top: isDiff ? 65 : 45,
                    right: isDiff ? 100 : 70,
                    child: const Text('🕊️', style: TextStyle(fontSize: 26)),
                  ),

                  // 8. Ovelha na arca
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
                  if (!isDiff)
                    Positioned(
                      top: 15,
                      right: 30,
                      child: Icon(Icons.cloud_rounded, size: 55, color: Colors.white.withOpacity(0.9)),
                    ),

                  // 10. Sol
                  Positioned(
                    top: 10,
                    left: 200,
                    child: Icon(Icons.wb_sunny_rounded, size: 40, color: Colors.amber.shade400),
                  ),

                  // --- HOTSPOTS DE ERRO ---
                  if (isDiff) ...[
                    _buildHotspot(0, top: 10, left: 35, width: 130, height: 70),
                    _buildHotspot(1, bottom: 90, right: 35, width: 55, height: 50),
                    _buildHotspot(2, bottom: 90, left: 105, width: 60, height: 50),
                    _buildHotspot(3, top: 35, right: 65, width: 80, height: 60),
                    _buildHotspot(4, bottom: 100, left: 200, width: 45, height: 45),
                    _buildHotspot(5, top: 10, right: 20, width: 70, height: 60),
                    _buildHotspot(6, top: 10, left: 190, width: 60, height: 50),
                  ],

                  // Feedback visual para clique incorreto
                  if (isDiff && _feedbackIncorretoPos != null)
                    Positioned(
                      left: _feedbackIncorretoPos!.dx - 18,
                      top: _feedbackIncorretoPos!.dy - 18,
                      child: const IgnorePointer(
                        child: _TemporaryErrorCircle(),
                      ),
                    ),
                ],
              ),
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
        behavior: HitTestBehavior.opaque,
        onTap: () => _marcarErro(erroIndex),
        child: Container(
          width: width,
          height: height,
          color: Colors.transparent,
          child: _AnimatedHotspotCircle(encontrado: encontrado, width: width, height: height),
        ),
      ),
    );
  }
}

// Círculo temporário vermelho para feedback de toque incorreto
class _TemporaryErrorCircle extends StatefulWidget {
  const _TemporaryErrorCircle();

  @override
  State<_TemporaryErrorCircle> createState() => _TemporaryErrorCircleState();
}

class _TemporaryErrorCircleState extends State<_TemporaryErrorCircle> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          border: Border.all(color: const Color(0xFFEF4444), width: 3),
          shape: BoxShape.circle,
        ),
        child: const Center(child: Icon(Icons.close_rounded, size: 20, color: Color(0xFFEF4444))),
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
    
    paint.color = Colors.red.shade400;
    canvas.drawArc(Rect.fromCircle(center: center, radius: 45), 3.14, 3.14, false, paint);
    
    paint.color = Colors.orange.shade400;
    canvas.drawArc(Rect.fromCircle(center: center, radius: 41), 3.14, 3.14, false, paint);

    paint.color = Colors.yellow.shade400;
    canvas.drawArc(Rect.fromCircle(center: center, radius: 37), 3.14, 3.14, false, paint);

    paint.color = Colors.green.shade400;
    canvas.drawArc(Rect.fromCircle(center: center, radius: 33), 3.14, 3.14, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
