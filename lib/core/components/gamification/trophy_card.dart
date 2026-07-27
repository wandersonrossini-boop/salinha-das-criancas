import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/typography.dart';
import '../../design_system/icon_tokens.dart';

class TrophyCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const TrophyCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DsSpacing.s16),
      decoration: BoxDecoration(
        color: DsColors.primaryYellow,
        borderRadius: DsRadius.large,
        boxShadow: DsElevation.floatCard,
        gradient: const LinearGradient(
          colors: [DsColors.primaryYellow, DsColors.warning],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(DsSpacing.s12),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconTokens.trophy,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: DsSpacing.s12),
          Text(
            title,
            style: DsTypography.heading2.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DsSpacing.s4),
          Text(
            subtitle,
            style: DsTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
