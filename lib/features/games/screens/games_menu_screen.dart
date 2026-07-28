import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'quiz_screen.dart';
import 'charadas_screen.dart';
import 'cronometro_screen.dart';
import 'jogo_memoria_screen.dart';
import 'jogo_sete_erros_screen.dart';
import '../../roulette/screens/roulette_screen.dart';

class GamesMenuScreen extends StatelessWidget {
  const GamesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Central de Jogos',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ) : null,
      ),
      body: Stack(
        children: [
          // Pastel background shapes (reduced opacity by 15%)
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE).withOpacity(0.20),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF).withOpacity(0.20),
                borderRadius: BorderRadius.circular(125),
              ),
            ),
          ),
          
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              children: [
                // Title and subtitle refined for premium layout and visibility
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        'Escolha uma dinâmica!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: const Text(
                          'Escolha uma dinâmica para sua aula.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildPremiumCard(
                  context,
                  'Quiz Bíblico',
                  'Perguntas bíblicas de múltipla escolha.',
                  Icons.help_outline_rounded,
                  [const Color(0xFF1E3A8A), const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
                  '🏆 Competitivo',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())),
                ),
                const SizedBox(height: 10),
                _buildPremiumCard(
                  context,
                  'Sorteio (Roleta)',
                  'Roleta interativa para sorteios e dinâmica.',
                  Icons.cached_rounded,
                  [const Color(0xFFB45309), const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                  '✨ Sorte',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RouletteScreen())),
                ),
                const SizedBox(height: 10),
                _buildPremiumCard(
                  context,
                  'Quem Sou Eu?',
                  'Descubra o personagem bíblico por dicas.',
                  Icons.psychology_rounded,
                  [const Color(0xFF5B21B6), const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
                  '🧠 Desafio',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CharadasScreen())),
                ),
                const SizedBox(height: 10),
                _buildPremiumCard(
                  context,
                  'Batata Quente',
                  'Passe o objeto antes que o tempo acabe.',
                  Icons.local_fire_department_rounded,
                  [const Color(0xFF991B1B), const Color(0xFFEF4444), const Color(0xFFF87171)],
                  '⏱ Tempo',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CronometroScreen())),
                ),
                const SizedBox(height: 10),
                _buildPremiumCard(
                  context,
                  'Jogo da Memória',
                  'Encontre os pares dos símbolos bíblicos.',
                  Icons.grid_view_rounded,
                  [const Color(0xFF065F46), const Color(0xFF10B981), const Color(0xFF34D399)],
                  '💡 Memória',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JogoMemoriaScreen())),
                ),
                const SizedBox(height: 10),
                _buildPremiumCard(
                  context,
                  'Jogo dos 7 Erros',
                  'Disputa interativa de encontrar os 7 erros.',
                  Icons.difference_rounded,
                  [const Color(0xFF155E75), const Color(0xFF06B6D4), const Color(0xFF22D3EE)],
                  '👁 Atenção',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JogoSeteErrosScreen())),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData iconData,
    List<Color> colors,
    String badgeText,
    VoidCallback onTap,
  ) {
    return _HoverScaleWrapper(
      onTap: onTap,
      colors: colors,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.0),
        child: Row(
          children: [
            // High fidelity 3D style illustrations
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              alignment: Alignment.center,
              child: Icon(
                iconData,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Chips premium 20% menores
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.88),
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // White translucent circular button with shadow and material chevron
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Stateful customizado para lidar com toque/hover estilo Duolingo
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
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: widget.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              // Sombras ricas em múltiplas camadas
              BoxShadow(
                color: widget.colors[0].withOpacity(_isPressed ? 0.15 : 0.22),
                blurRadius: _isPressed ? 10 : 16,
                spreadRadius: _isPressed ? -1 : -2,
                offset: Offset(0, _isPressed ? 3 : 6),
              ),
              BoxShadow(
                color: widget.colors[1].withOpacity(_isPressed ? 0.1 : 0.15),
                blurRadius: _isPressed ? 6 : 10,
                spreadRadius: -2,
                offset: Offset(0, _isPressed ? 1 : 3),
              ),
              // Iluminação interna suave
              BoxShadow(
                color: Colors.white.withOpacity(0.15),
                blurRadius: 4,
                spreadRadius: -1,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
