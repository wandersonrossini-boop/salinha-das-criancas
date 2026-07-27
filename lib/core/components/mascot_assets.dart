import 'package:flutter/material.dart';

/// Centralização oficial de todos os assets da mascote "Ovelhinha".
/// Toda tela do aplicativo consome este mapeamento para garantir consistência.
class MascotAssets {
  // --- POSES OFICIAIS ---
  static const String front = 'assets/mascot/poses/front.png';
  static const String threeQuarter = 'assets/mascot/poses/front_right.png'; // 3/4 correspondente
  static const String side = 'assets/mascot/poses/side.png';
  static const String back = 'assets/mascot/poses/back.png';
  static const String idle = 'assets/mascot/poses/idle.png';
  static const String transparentSheep = 'assets/mascot/poses/transparent_sheep.png';

  // --- EXPRESSÕES ---
  static const String happy = 'assets/mascot/expressions/happy.png';
  static const String smile = 'assets/mascot/expressions/smile.png';
  static const String surprised = 'assets/mascot/expressions/surprised.png';
  static const String thinkingExpression = 'assets/mascot/expressions/thinking.png';
  static const String wink = 'assets/mascot/expressions/wink.png';

  // --- AÇÕES ---
  static const String wave = 'assets/mascot/actions/wave.png';
  static const String welcome = 'assets/mascot/actions/welcome.png';
  static const String pointingLeft = 'assets/mascot/actions/pointing.png'; // Mapeado para o apontamento padrão
  static const String pointingRight = 'assets/mascot/actions/pointing.png';
  static const String readingBible = 'assets/mascot/actions/reading.png';
  static const String praying = 'assets/mascot/actions/praying.png';
  static const String love = 'assets/mascot/actions/love.png';
  static const String sleep = 'assets/mascot/actions/sleep.png';
}

/// Widget reutilizável para renderização da mascote oficial com fallbacks seguros.
class MascotWidget extends StatelessWidget {
  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;

  const MascotWidget({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback em emoji caso a imagem física não tenha sido carregada/cacheada localmente
        return Center(
          child: Text(
            _getEmojiFallback(),
            style: TextStyle(fontSize: (width ?? 48) * 0.6),
          ),
        );
      },
    );
  }

  String _getEmojiFallback() {
    if (asset.contains('reading') || asset.contains('bible')) return '📖🐑';
    if (asset.contains('praying')) return '🙏🐑';
    if (asset.contains('love')) return '❤️🐑';
    if (asset.contains('sleep')) return '😴🐑';
    if (asset.contains('wave') || asset.contains('welcome')) return '👋🐑';
    return '🐑';
  }
}
