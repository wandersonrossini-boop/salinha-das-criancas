import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class PremiumSegmentedButton<T> extends StatelessWidget {
  final List<T> segments;
  final T selected;
  final ValueChanged<T> onSelectionChanged;

  const PremiumSegmentedButton({
    Key? key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: segments.map((e) => GestureDetector(
          onTap: () => onSelectionChanged(e),
          child: Text(e.toString()),
        )).toList(),
      ),
    );
  }
}
