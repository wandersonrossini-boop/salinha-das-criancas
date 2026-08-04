import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/design_system/colors.dart';
import '../../../core/db/database_helper.dart';
import '../../../core/services/audio_service.dart';
import '../../students/models/student.dart';

class BatataQuenteScreen extends StatefulWidget {
  const BatataQuenteScreen({super.key});

  @override
  State<BatataQuenteScreen> createState() => _BatataQuenteScreenState();
}

class _BatataQuenteScreenState extends State<BatataQuenteScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _timer;
  bool _isPlaying = false;
  int _secondsLeft = 0;
  String _lessonTheme = 'Aula de Hoje';
  List<String> _quizQuestions = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.9,
      upperBound: 1.15,
    );
    _loadLessonData();
  }

  Future<void> _loadLessonData() async {
    final plan = await DatabaseHelper.instance.fetchLessonOfTheWeek();
    if (plan != null) {
      setState(() {
        _lessonTheme = plan.title;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    AudioService.instance.stopTick();
    super.dispose();
  }

  void _startBatata() {
    _timer?.cancel();
    // Tempo maluco cego entre 12 e 35 segundos
    _secondsLeft = 12 + _random.nextInt(24);
    _pulseController.repeat(reverse: true);
    AudioService.instance.playTick();

    setState(() {
      _isPlaying = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        _secondsLeft--;
      } else {
        _timer?.cancel();
        _pulseController.stop();
        _burnBatata();
      }
    });
  }

  void _burnBatata() {
    AudioService.instance.stopTick();
    AudioService.instance.playExplosionOrWhistle();

    setState(() {
      _isPlaying = false;
    });

    _showConsequenceModal();
  }

  void _showConsequenceModal() {
    final types = ['pergunta', 'mico', 'presentear', 'orar'];
    final selectedType = types[_random.nextInt(types.length)];

    String title = '';
    String icon = '';
    String description = '';
    Color cardColor = Colors.orange;

    switch (selectedType) {
      case 'pergunta':
        icon = '🧠';
        title = 'PERGUNTA DO TEMA';
        description = 'Responda para a turma: Qual foi a grande lição que aprendemos na aula "$_lessonTheme"?';
        cardColor = Colors.blue.shade600;
        break;
      case 'mico':
        icon = '🎭';
        title = 'PAGAR UM MICO';
        description = 'Faça uma mímica divertida ou encene um personagem da história de hoje para a turma adivinhar!';
        cardColor = Colors.purple.shade600;
        break;
      case 'presentear':
        icon = '🎁';
        title = 'PRESENTEAR ALGUÉM';
        description = 'Entregue um desenho ou adesivo especial para um colega que ainda não recebeu hoje!';
        cardColor = Colors.amber.shade700;
        break;
      case 'orar':
        icon = '🤲';
        title = 'ORAR POR UM COLEGA';
        description = 'Dê a mão para o amiguinho ao seu lado e faça uma linda oração de 10 segundos abençoando a vida dele!';
        cardColor = Colors.green.shade600;
        break;
    }

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
              Text('💥 QUEIMOU! 💥', style: TextStyle(fontFamily: 'Fredoka', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardColor, width: 2),
                ),
                child: Column(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(title, style: TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: cardColor)),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, height: 1.4, color: Color(0xFF1E293B)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _startBatata();
                },
                icon: const Icon(Icons.local_fire_department_rounded),
                label: const Text('Próxima Rodada 🔥', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.laranjaCriativo,
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
      backgroundColor: const Color(0xFFFFFBEB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Batata Quente 🔥',
          style: TextStyle(fontFamily: 'Fredoka', color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Tempo Maluco Cego',
                      style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
                  ],
                ),
              ),
              ScaleTransition(
                scale: _pulseController,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _isPlaying ? Colors.red.shade100 : Colors.amber.shade50,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _isPlaying ? Colors.red.withOpacity(0.3) : Colors.amber.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isPlaying ? '🥔🔥' : '🥔',
                      style: const TextStyle(fontSize: 90),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    _isPlaying ? 'Passe a batata rápido antes que ela queime!' : 'Toque no botão para iniciar o Tempo Maluco!',
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isPlaying ? null : _startBatata,
                    icon: Icon(_isPlaying ? Icons.hourglass_top_rounded : Icons.local_fire_department_rounded),
                    label: Text(
                      _isPlaying ? 'A BATATA ESTÁ PASSANDO! 💥' : '🔥 Iniciar Batata Quente',
                      style: const TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.laranjaCriativo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
