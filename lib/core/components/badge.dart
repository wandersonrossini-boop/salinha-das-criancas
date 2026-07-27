import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/radius.dart';
import '../design_system/spacing.dart';

class DsBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const DsBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.s12,
        vertical: DsSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: DsRadius.pill,
      ),
      child: Text(
        label.toUpperCase(),
        style: DsTypography.badgeText,
      ),
    );
  }
}
