import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class StudentCard extends StatelessWidget {
  final String name;
  final String avatarUrl;

  const StudentCard({Key? key, required this.name, required this.avatarUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DsColors.surface,
        borderRadius: BorderRadius.circular(DsRadius.large),
        boxShadow: DsElevation.floatCard,
      ),
      padding: EdgeInsets.all(DsSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(avatarUrl),
            radius: 24,
          ),
          SizedBox(width: DsSpacing.sm),
          Text(name, style: DsTypography.headingSmall),
        ],
      ),
    );
  }
}
