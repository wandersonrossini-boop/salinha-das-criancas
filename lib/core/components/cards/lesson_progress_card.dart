import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class LessonProgressCard extends StatelessWidget {
  final String lessonTitle;
  final double progress;

  const LessonProgressCard({Key? key, required this.lessonTitle, required this.progress}) : super(key: key);

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
          Text(lessonTitle, style: DsTypography.headingSmall),
          SizedBox(height: DsSpacing.sm),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: DsColors.surfaceVariant,
            color: DsColors.primary,
          ),
          SizedBox(height: DsSpacing.xs),
          Text('${(progress * 100).toInt()}% completed', style: DsTypography.bodySmall),
        ],
      ),
    );
  }
}
