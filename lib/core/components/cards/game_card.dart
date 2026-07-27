import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class GameCard extends StatelessWidget {
  final String gameName;
  final VoidCallback onTap;

  const GameCard({Key? key, required this.gameName, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DsColors.primaryContainer,
          borderRadius: BorderRadius.circular(DsRadius.large),
          boxShadow: DsElevation.floatCard,
        ),
        padding: EdgeInsets.all(DsSpacing.md),
        child: Row(
          children: [
            Icon(DsIconTokens.gamepad, color: DsColors.onPrimaryContainer),
            SizedBox(width: DsSpacing.sm),
            Text(gameName, style: DsTypography.headingSmall.copyWith(color: DsColors.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }
}
