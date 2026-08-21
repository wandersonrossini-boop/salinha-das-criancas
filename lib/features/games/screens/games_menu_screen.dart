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
          'Jogos e Dinâmicas',
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
          // Pastel background shapes
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: const Text(
                        'Escolha uma atividade para complementar sua aula.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Non-scrollable layout divided into 3 equal rows using Expanded
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        children: [
                          // Row 1
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: IllustratedGameCard(
                                    title: 'Quiz Bíblico',
                                    badge: 'Competitivo',
                                    imagePath: 'assets/images/games/game_quiz_biblico.png',
                                    backgroundColor: const Color(0xFFEEF5FF),
                                    borderColor: const Color(0xFFD0E0FF),
                                    accentColor: Colors.blue,
                                    semanticLabel: 'Abrir Quiz Bíblico',
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: IllustratedGameCard(
                                    title: 'Roleta de Sorteios',
                                    badge: 'Sorte',
                                    imagePath: 'assets/images/games/game_roleta.png',
                                    backgroundColor: const Color(0xFFFFF6E5),
                                    borderColor: const Color(0xFFFFE3C8),
                                    accentColor: Colors.orange,
                                    semanticLabel: 'Abrir Roleta de Sorteios',
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RouletteScreen())),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Row 2
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: IllustratedGameCard(
                                    title: 'Quem Sou Eu?',
                                    badge: 'Desafio',
                                    imagePath: 'assets/images/games/game_quem_sou_eu.png',
                                    backgroundColor: const Color(0xFFF7F0FF),
                                    borderColor: const Color(0xFFE4D3F9),
                                    accentColor: Colors.purple,
                                    semanticLabel: 'Abrir jogo Quem Sou Eu',
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CharadasScreen())),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: IllustratedGameCard(
                                    title: 'Batata Quente',
                                    badge: 'Tempo',
                                    imagePath: 'assets/images/games/game_batata_quente.png',
                                    backgroundColor: const Color(0xFFFFF0F1),
                                    borderColor: const Color(0xFFFFD4D4),
                                    accentColor: const Color(0xFFFF7F50),
                                    semanticLabel: 'Abrir Batata Quente',
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CronometroScreen())),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Row 3
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: IllustratedGameCard(
                                    title: 'Jogo da Memória',
                                    badge: 'Memória',
                                    imagePath: 'assets/images/games/game_memoria.png',
                                    backgroundColor: const Color(0xFFEDFAF4),
                                    borderColor: const Color(0xFFC6F4DC),
                                    accentColor: Colors.green,
                                    scale: 1.15,
                                    semanticLabel: 'Abrir Jogo da Memória',
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JogoMemoriaScreen())),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: IllustratedGameCard(
                                    title: 'Jogo dos 7 Erros',
                                    badge: 'Atenção',
                                    imagePath: 'assets/images/games/game_sete_erros.png',
                                    backgroundColor: const Color(0xFFECF9FC),
                                    borderColor: const Color(0xFFBFEFEE),
                                    accentColor: Colors.cyan,
                                    scale: 1.15,
                                    semanticLabel: 'Abrir Jogo dos 7 Erros',
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
            ),
          ),
        ],
      ),
    );
  }
}

class IllustratedGameCard extends StatefulWidget {
  final String title;
  final String badge;
  final String imagePath;
  final Color backgroundColor;
  final Color borderColor;
  final Color accentColor;
  final VoidCallback onTap;
  final String semanticLabel;
  final double scale;

  const IllustratedGameCard({
    super.key,
    required this.title,
    required this.badge,
    required this.imagePath,
    required this.backgroundColor,
    required this.borderColor,
    required this.accentColor,
    required this.onTap,
    required this.semanticLabel,
    this.scale = 1.0,
  });

  @override
  State<IllustratedGameCard> createState() => _IllustratedGameCardState();
}

class _IllustratedGameCardState extends State<IllustratedGameCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: widget.borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: widget.borderColor,
                  offset: const Offset(0, 2),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 55,
                      child: Container(
                        alignment: Alignment.center,
                        child: Transform.scale(
                          scale: widget.scale,
                          child: Image.asset(
                            widget.imagePath,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Erro ao carregar imagem: ${widget.imagePath}');
                              return Icon(
                                Icons.image_not_supported_rounded, 
                                size: 48, 
                                color: widget.accentColor.withOpacity(0.5)
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      flex: 45,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A2B4C),
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.badge,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: widget.accentColor,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
