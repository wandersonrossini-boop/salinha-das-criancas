import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;

  const DashboardCard({Key? key, required this.title, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DsColors.surfaceWhite,
        borderRadius: DsRadius.large,
        boxShadow: DsElevation.floatCard,
      ),
      padding: const EdgeInsets.all(DsSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DsTypography.heading3),
          const SizedBox(height: DsSpacing.s8),
          child,
        ],
      ),
    );
  }
}
