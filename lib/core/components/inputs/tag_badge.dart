import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class TagBadge extends StatelessWidget {
  final String label;

  const TagBadge({
    Key? key,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label),
    );
  }
}
