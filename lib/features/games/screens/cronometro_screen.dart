import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CronometroScreen extends StatefulWidget {
  const CronometroScreen({super.key});

  @override
  State<CronometroScreen> createState() => _CronometroScreenState();
}

class _CronometroScreenState extends State<CronometroScreen> {
  int _timeLeft = 0;
  int _initialTime = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _isFinished = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _timeLeft = seconds;
      _initialTime = seconds;
      _isRunning = false;
      _isFinished = false;
    });
  }

  void _startTimer() {
    if (_timeLeft == 0) return;
    
    setState(() {
      _isRunning = true;
      _isFinished = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        _onTimeUp();
      }
    });
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📖 Regras - Cronômetro'),
        content: const Text(
          '1. Defina um tempo (15s, 30s ou 1 min).\n'
          '2. Inicie a contagem e faça a brincadeira (ex: Batata Quente).\n'
          '3. Quando zerar, a tela piscará em vermelho com um alarme forte!'
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

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _onTimeUp() async {
    setState(() {
      _isRunning = false;
      _isFinished = true;
    });
    // Pisca a tela (som removido temporariamente para evitar crash na web)
  }

  @override
  Widget build(BuildContext context) {
    // Fundo pisca vermelho se esgotar
    final bgColor = _isFinished ? AppColors.alerta : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Cronômetro', style: TextStyle(fontWeight: FontWeight.bold, color: _isFinished ? Colors.white : Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _isFinished ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: _isFinished ? Colors.white : AppColors.azulCeleste),
            onPressed: _showHelp,
            tooltip: 'Regras',
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_isFinished)
                const Text(
                  'TEMPO ESGOTADO!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                  textAlign: TextAlign.center,
                ),
                
              // Cronômetro Circular Responsivo
              Center(
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isFinished ? Colors.white : AppColors.azulCeleste.withOpacity(0.1),
                    border: Border.all(color: _isFinished ? Colors.transparent : AppColors.azulCeleste, width: 10),
                    boxShadow: _isFinished
                        ? [BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 40, spreadRadius: 10)]
                        : [],
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${_timeLeft}s',
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: _isFinished ? AppColors.alerta : AppColors.azulCeleste,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Controles Principais Uniformes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _isRunning ? null : _startTimer,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: _isRunning ? Colors.grey[300] : const Color(0xFF06D6A0),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isRunning ? [] : [
                          BoxShadow(
                            color: const Color(0xFF06D6A0).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: _isRunning ? Colors.grey[500] : Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'INICIAR',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.bold,
                              color: _isRunning ? Colors.grey[500] : Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isRunning ? _pauseTimer : null,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: !_isRunning ? Colors.grey[300] : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: !_isRunning ? [] : [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pause_rounded, color: !_isRunning ? Colors.grey[500] : Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'PAUSAR',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.bold,
                              color: !_isRunning ? Colors.grey[500] : Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      _timer?.cancel();
                      setState(() {
                        _timeLeft = _initialTime;
                        _isRunning = false;
                        _isFinished = false;
                      });
                    },
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 20),
                    ),
                  ),
                ],
              ),

              // Atalhos no Rodapé (Material 3 ChoiceChips)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [15, 30, 60].map((time) {
                      final label = time == 60 ? '1m' : '${time}s';
                      return ChoiceChip(
                        label: Text(label),
                        selected: _initialTime == time,
                        onSelected: (selected) {
                          if (selected) _setTimer(time);
                        },
                        selectedColor: AppColors.azulCeleste.withOpacity(0.15),
                        labelStyle: TextStyle(
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.bold,
                          color: _initialTime == time ? AppColors.azulCeleste : AppColors.textSecondary,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton(int seconds, String label) {
    return ElevatedButton(
      onPressed: () => _setTimer(seconds),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.azulCeleste.withOpacity(0.5)),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
