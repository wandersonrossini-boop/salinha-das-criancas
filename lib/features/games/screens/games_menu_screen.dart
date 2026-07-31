import 'package:flutter/material.dart';
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
          'Jogos e Dinâmicas',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ) : null,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text(
              'Escolha uma atividade para complementar sua aula.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13.5,
                color: Color(0xFF4A5568),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildGameCard(
                            context: context,
                            title: 'Quiz Bíblico',
                            imageAsset: 'assets/images/games/game_quiz_biblico.png',
                            category: 'COMPETITIVO',
                            bgColor: const Color(0xFFEEF5FF),
                            borderColor: const Color(0xFFD0E0FF),
                            badgeBgColor: const Color(0xFFE0ECFF),
                            badgeTextColor: const Color(0xFF2B6CB0),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGameCard(
                            context: context,
                            title: 'Roleta de Sorteios',
                            imageAsset: 'assets/images/games/game_roleta.png',
                            category: 'SORTE',
                            bgColor: const Color(0xFFFFF6E5),
                            borderColor: const Color(0xFFFFE3C8),
                            badgeBgColor: const Color(0xFFFFF0D4),
                            badgeTextColor: const Color(0xFFB7791F),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RouletteScreen())),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildGameCard(
                            context: context,
                            title: 'Quem Sou Eu?',
                            imageAsset: 'assets/images/games/game_quem_sou_eu.png',
                            category: 'DESAFIO',
                            bgColor: const Color(0xFFF7F0FF),
                            borderColor: const Color(0xFFE4D3F9),
                            badgeBgColor: const Color(0xFFF0E5FF),
                            badgeTextColor: const Color(0xFF6B46C1),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CharadasScreen())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGameCard(
                            context: context,
                            title: 'Batata Quente',
                            imageAsset: 'assets/images/games/game_batata_quente.png',
                            category: 'TEMPO',
                            bgColor: const Color(0xFFFFF0F1),
                            borderColor: const Color(0xFFFFD4D4),
                            badgeBgColor: const Color(0xFFFFE2E5),
                            badgeTextColor: const Color(0xFFC53030),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CronometroScreen())),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildGameCard(
                            context: context,
                            title: 'Jogo da Memória',
                            imageAsset: 'assets/images/games/game_memoria.png',
                            category: 'MEMÓRIA',
                            bgColor: const Color(0xFFEDFAF4),
                            borderColor: const Color(0xFFC6F4DC),
                            badgeBgColor: const Color(0xFFDCF7E9),
                            badgeTextColor: const Color(0xFF276749),
                            imageScale: 1.15,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JogoMemoriaScreen())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGameCard(
                            context: context,
                            title: 'Jogo dos 7 Erros',
                            imageAsset: 'assets/images/games/game_sete_erros.png',
                            category: 'ATENÇÃO',
                            bgColor: const Color(0xFFECF9FC),
                            borderColor: const Color(0xFFBFEFEE),
                            badgeBgColor: const Color(0xFFDBF5F8),
                            badgeTextColor: const Color(0xFF2C7A7B),
                            imageScale: 1.15,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JogoSeteErrosScreen())),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required String title,
    required String imageAsset,
    required String category,
    required Color bgColor,
    required Color borderColor,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required VoidCallback onTap,
    double imageScale = 1.0,
  }) {
    return _HoverScaleGridWrapper(
      onTap: onTap,
      bgColor: bgColor,
      borderColor: borderColor,
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
              child: Transform.scale(
                scale: imageScale,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B4C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeTextColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverScaleGridWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color bgColor;
  final Color borderColor;

  const _HoverScaleGridWrapper({
    required this.child,
    required this.onTap,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  State<_HoverScaleGridWrapper> createState() => _HoverScaleGridWrapperState();
}

class _HoverScaleGridWrapperState extends State<_HoverScaleGridWrapper> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              top: BorderSide(color: widget.borderColor, width: 2),
              left: BorderSide(color: widget.borderColor, width: 2),
              right: BorderSide(color: widget.borderColor, width: 2),
              bottom: BorderSide(color: widget.borderColor, width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
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
