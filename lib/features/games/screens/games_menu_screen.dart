import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import 'charadas_screen.dart';
import 'jogo_memoria_screen.dart';
import 'match_pairs_screen.dart';
import 'batata_quente_screen.dart';
import '../../roulette/screens/roulette_screen.dart';

class GamesMenuScreen extends StatelessWidget {
  final String? linkedLessonTitle;
  const GamesMenuScreen({super.key, this.linkedLessonTitle});

  void _showColoringSheetsModal(BuildContext context, String lessonTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '🎨 Desenhos de Apoio: $lessonTitle',
                    style: const TextStyle(fontFamily: 'Fredoka', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Materiais em PDF e imagens para colorir pré-filtrados para esta lição:',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildColoringCard(
                    ctx,
                    title: 'Desenho Principal para Colorir',
                    subtitle: 'Ilustração temática da história para colorir na salinha.',
                    icon: Icons.draw_rounded,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _buildColoringCard(
                    ctx,
                    title: 'Atividade de Caça-Palavras',
                    subtitle: 'Folha de exercícios com termos da aula de hoje.',
                    icon: Icons.grid_on_rounded,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildColoringCard(
                    ctx,
                    title: 'Cartão de Versículo para Levar para Casa',
                    subtitle: 'Lembrancinha com o versículo chave para os pais.',
                    icon: Icons.card_giftcard_rounded,
                    color: Colors.amber.shade800,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColoringCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Fredoka', fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12.5, color: Color(0xFF334155))),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📥 Download iniciado para: $title'),
                  backgroundColor: color,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('PDF', style: TextStyle(fontFamily: 'Fredoka', fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTitle = linkedLessonTitle ?? 'Aula de Hoje';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Jogos e Dinâmicas 🎨',
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (linkedLessonTitle != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Atividades Vinculadas: $linkedLessonTitle',
                          style: TextStyle(fontFamily: 'Fredoka', fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              
              // Cabeçalho com largura total garantida para o texto
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  children: [
                    const Text(
                      'Escolha uma atividade ou jogo para complementar sua aula.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: Color(0xFF4A5568),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showColoringSheetsModal(context, activeTitle),
                        icon: const Icon(Icons.palette_rounded, size: 18),
                        label: const Text(
                          '🎨 Desenhos e Folhas de Apoio para Colorir (PDF)',
                          style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple.shade700,
                          side: BorderSide(color: Colors.purple.shade300, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Grade Responsiva de Jogos
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.15,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildGameCard(
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
                    _buildGameCard(
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
                    _buildGameCard(
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
                    _buildGameCard(
                      context: context,
                      title: 'Batata Quente',
                      imageAsset: 'assets/images/games/game_batata_quente.png',
                      category: 'TEMPO',
                      bgColor: const Color(0xFFFFF0F1),
                      borderColor: const Color(0xFFFFD4D4),
                      badgeBgColor: const Color(0xFFFFE2E5),
                      badgeTextColor: const Color(0xFFC53030),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BatataQuenteScreen())),
                    ),
                    _buildGameCard(
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
                    _buildGameCard(
                      context: context,
                      title: 'Ligue os Pares',
                      imageAsset: 'assets/images/games/game_sete_erros.png',
                      category: 'ASSOCIAÇÃO',
                      bgColor: const Color(0xFFECF9FC),
                      borderColor: const Color(0xFFBFEFEE),
                      badgeBgColor: const Color(0xFFDBF5F8),
                      badgeTextColor: const Color(0xFF2C7A7B),
                      imageScale: 1.15,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchPairsScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: badgeTextColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: Transform.scale(
                scale: imageScale,
                child: Image.asset(
                  imageAsset,
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.sports_esports_rounded, size: 48, color: badgeTextColor);
                  },
                ),
              ),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: widget.bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered ? widget.borderColor.withOpacity(0.8) : widget.borderColor,
                width: _isHovered ? 2.5 : 1.5,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.borderColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
