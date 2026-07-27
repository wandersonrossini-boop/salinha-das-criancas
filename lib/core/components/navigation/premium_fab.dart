import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class PremiumFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;

  const PremiumFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [AppElevation.shadowMd],
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Material(
        color: backgroundColor ?? AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.circular),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.circular),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.circular),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child: Icon(
              icon,
              color: iconColor ?? Colors.white,
              size: AppIconTokens.md,
            ),
          ),
        ),
      ),
    );
  }
}
