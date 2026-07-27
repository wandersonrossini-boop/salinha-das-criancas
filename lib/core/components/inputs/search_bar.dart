import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class PremiumSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;

  const PremiumSearchBar({
    Key? key,
    this.hintText = 'Search...',
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // placeholder for search bar
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
        ),
      ),
    );
  }
}
