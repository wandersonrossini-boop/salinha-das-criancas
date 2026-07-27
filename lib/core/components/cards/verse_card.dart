import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class VerseCard extends StatelessWidget {
  final String verse;
  final String reference;

  const VerseCard({Key? key, required this.verse, required this.reference}) : super(key: key);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(DsIconTokens.book, color: DsColors.primary),
          SizedBox(height: DsSpacing.sm),
          Text(verse, style: DsTypography.bodyLarge),
          SizedBox(height: DsSpacing.xs),
          Text(reference, style: DsTypography.bodySmall.copyWith(color: DsColors.textSecondary)),
        ],
      ),
    );
  }
}
