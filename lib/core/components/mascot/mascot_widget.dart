import 'package:flutter/material.dart';
import 'mascot_assets.dart';

enum MascotPose {
  front,
  frontRight, // mapped to front as fallback if front_right is missing, or we can resolve it directly
  side,
  back,
  idle,
}

enum MascotExpression {
  happy,
  smile,
  thinking,
  surprised,
  wink,
}

enum MascotAction {
  welcome,
  wave,
  reading,
  praying,
  love,
  pointing,
  sleep,
}

/// Componente oficial de exibição da mascote "Ovelhinha".
/// Resolve o caminho dos assets a partir de Enums formais do Design System.
class MascotWidget extends StatelessWidget {
  final MascotPose? pose;
  final MascotExpression? expression;
  final MascotAction? action;
  final double? width;
  final double? height;
  final BoxFit fit;

  const MascotWidget({
    super.key,
    this.pose,
    this.expression,
    this.action,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final String assetPath = _getAssetPath();
    
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback em emoji caso a imagem física não tenha sido carregada/cacheada localmente
        return Center(
          child: Text(
            _getEmojiFallback(assetPath),
            style: TextStyle(fontSize: (width ?? 48) * 0.6),
          ),
        );
      },
    );
  }

  String _getAssetPath() {
    if (pose != null) {
      switch (pose!) {
        case MascotPose.front:
          return MascotAssets.front;
        case MascotPose.frontRight:
          return 'assets/images/mascot/poses/front_right.png';
        case MascotPose.side:
          return MascotAssets.side;
        case MascotPose.back:
          return MascotAssets.back;
        case MascotPose.idle:
          return MascotAssets.idle;
      }
    }
    
    if (expression != null) {
      switch (expression!) {
        case MascotExpression.happy:
          return MascotAssets.happy;
        case MascotExpression.smile:
          return MascotAssets.smile;
        case MascotExpression.thinking:
          return MascotAssets.thinking;
        case MascotExpression.surprised:
          return MascotAssets.surprised;
        case MascotExpression.wink:
          return MascotAssets.wink;
      }
    }

    if (action != null) {
      switch (action!) {
        case MascotAction.welcome:
          return MascotAssets.welcome;
        case MascotAction.wave:
          return MascotAssets.wave;
        case MascotAction.reading:
          return MascotAssets.reading;
        case MascotAction.praying:
          return MascotAssets.praying;
        case MascotAction.love:
          return MascotAssets.love;
        case MascotAction.pointing:
          return MascotAssets.pointing;
        case MascotAction.sleep:
          return MascotAssets.sleep;
      }
    }

    // Default fallback
    return MascotAssets.front;
  }

  String _getEmojiFallback(String path) {
    if (path.contains('reading')) return '📖🐑';
    if (path.contains('praying')) return '🙏🐑';
    if (path.contains('love')) return '❤️🐑';
    if (path.contains('sleep')) return '😴🐑';
    if (path.contains('wave') || path.contains('welcome')) return '👋🐑';
    return '🐑';
  }
}
