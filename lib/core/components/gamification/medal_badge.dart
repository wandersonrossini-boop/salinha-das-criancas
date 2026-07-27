import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/typography.dart';
import '../../design_system/icon_tokens.dart';

class MedalBadge extends StatelessWidget {
  final String label;

  const MedalBadge({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.s12,
        vertical: DsSpacing.s8,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DsColors.primaryOrange, DsColors.warning],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: DsRadius.pill,
        boxShadow: DsElevation.glow(DsColors.primaryOrange),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            IconTokens.medal,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: DsSpacing.s4),
          Text(
            label,
            style: DsTypography.badgeText.copyWith(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
