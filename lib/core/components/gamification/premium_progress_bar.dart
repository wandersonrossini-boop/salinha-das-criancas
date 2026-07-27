import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';

class PremiumProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final double height;

  const PremiumProgressBar({
    super.key,
    required this.progress,
    this.color = DsColors.primaryGreen,
    this.height = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: DsColors.borderColor,
        borderRadius: DsRadius.pill,
        boxShadow: DsElevation.subtle,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth * progress.clamp(0.0, 1.0);
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutQuart,
                width: barWidth,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: DsRadius.pill,
                  boxShadow: DsElevation.glow(color),
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.8),
                      color,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              // Shimmer / Shine effect
              Positioned(
                left: barWidth > 20 ? barWidth - 20 : 0,
                top: 2,
                bottom: 2,
                child: Container(
                  width: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: DsRadius.pill,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
