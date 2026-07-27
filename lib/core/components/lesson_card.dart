import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/radius.dart';
import '../design_system/spacing.dart';
import '../design_system/elevation.dart';
import '../design_system/animations.dart';

class LessonCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String illustration;
  final Color themeColor;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.themeColor,
    required this.onTap,
  });

  @override
  State<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: DsAnimations.fast,
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.reverse(),
      onTapUp: (_) {
        _scaleController.forward();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.forward(),
      child: ScaleTransition(
        scale: _scaleController,
        child: Container(
          decoration: BoxDecoration(
            color: DsColors.surfaceWhite,
            borderRadius: DsRadius.large,
            border: Border.all(color: DsColors.surfaceWhite.withOpacity(0.8), width: 1.5),
            boxShadow: DsElevation.floatCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Área da Ilustração
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.themeColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(DsRadius.vLarge),
                      topRight: Radius.circular(DsRadius.vLarge),
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      widget.illustration,
                      fit: BoxFit.contain,
                      height: 100, // Ajuste dinâmico depois
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image, size: 64, color: widget.themeColor.withOpacity(0.3));
                      },
                    ),
                  ),
                ),
              ),
              // Área de Texto
              Padding(
                padding: const EdgeInsets.all(DsSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: DsTypography.heading3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DsSpacing.s4),
                    Text(
                      widget.subtitle,
                      style: DsTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
