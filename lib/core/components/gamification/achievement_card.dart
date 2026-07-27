import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/typography.dart';
import '../../design_system/icon_tokens.dart';

class AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  const AchievementCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = IconTokens.star,
    this.isUnlocked = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isUnlocked ? DsColors.surfaceWhite : DsColors.background;
    final Color iconColor = isUnlocked ? DsColors.primaryBlue : DsColors.textDisabled;
    final Color textColor = isUnlocked ? DsColors.textHighEmphasis : DsColors.textDisabled;

    return Container(
      padding: const EdgeInsets.all(DsSpacing.s16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: DsRadius.medium,
        boxShadow: isUnlocked ? DsElevation.subtle : null,
        border: Border.all(
          color: isUnlocked ? DsColors.primaryBlue.withOpacity(0.3) : DsColors.borderColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DsSpacing.s12),
            decoration: BoxDecoration(
              color: isUnlocked ? DsColors.primaryBlue.withOpacity(0.1) : DsColors.borderColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 32,
            ),
          ),
          const SizedBox(width: DsSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DsTypography.heading3.copyWith(color: textColor),
                ),
                const SizedBox(height: DsSpacing.s4),
                Text(
                  description,
                  style: DsTypography.bodyMedium.copyWith(color: isUnlocked ? DsColors.textMediumEmphasis : DsColors.textDisabled),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
