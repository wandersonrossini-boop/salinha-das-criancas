import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const StatsCard({Key? key, required this.label, required this.value, required this.icon}) : super(key: key);

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
        children: [
          Icon(icon, color: DsColors.primary, size: 24),
          SizedBox(height: DsSpacing.xs),
          Text(value, style: DsTypography.headingMedium),
          Text(label, style: DsTypography.bodySmall),
        ],
      ),
    );
  }
}
