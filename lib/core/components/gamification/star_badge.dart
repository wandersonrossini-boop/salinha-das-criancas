import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/typography.dart';
import '../../design_system/icon_tokens.dart';

class StarBadge extends StatelessWidget {
  final int count;

  const StarBadge({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.s12,
        vertical: DsSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: DsColors.primaryYellow,
        borderRadius: DsRadius.pill,
        boxShadow: DsElevation.glow(DsColors.primaryYellow),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            IconTokens.star,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: DsSpacing.s4),
          Text(
            count.toString(),
            style: DsTypography.badgeText.copyWith(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
