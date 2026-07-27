import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class TeamCard extends StatelessWidget {
  final String teamName;
  final int points;

  const TeamCard({Key? key, required this.teamName, required this.points}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DsColors.surface,
        borderRadius: BorderRadius.circular(DsRadius.large),
        boxShadow: DsElevation.floatCard,
      ),
      padding: EdgeInsets.all(DsSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(DsIconTokens.group, color: DsColors.primary, size: 32),
          SizedBox(height: DsSpacing.sm),
          Text(teamName, style: DsTypography.headingMedium),
          SizedBox(height: DsSpacing.xs),
          Text('$points pts', style: DsTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
