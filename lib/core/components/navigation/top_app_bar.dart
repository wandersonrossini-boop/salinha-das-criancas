import 'dart:ui';
import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class PremiumTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const PremiumTopAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: AppSpacing.sm,
            right: AppSpacing.sm,
          ),
          height: preferredSize.height + MediaQuery.of(context).padding.top,
          child: Row(
            children: [
              if (leading != null) leading!
              else if (Navigator.canPop(context))
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: AppIconTokens.sm),
                  color: AppColors.textPrimary,
                  onPressed: () => Navigator.pop(context),
                )
              else
                const SizedBox(width: AppSpacing.xl),
                
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              if (actions != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                )
              else
                const SizedBox(width: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
