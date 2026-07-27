import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class AiMessageCard extends StatelessWidget {
  final String message;

  const AiMessageCard({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DsColors.secondaryContainer,
        borderRadius: BorderRadius.circular(DsRadius.large),
        boxShadow: DsElevation.floatCard,
      ),
      padding: EdgeInsets.all(DsSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(DsIconTokens.smartToy, color: DsColors.onSecondaryContainer),
          SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: DsTypography.bodyMedium.copyWith(color: DsColors.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
