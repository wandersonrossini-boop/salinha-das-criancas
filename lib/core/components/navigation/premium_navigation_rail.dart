import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';
import 'dart:ui';

class PremiumNavigationRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PremiumNavigationRailItem> items;
  final Widget? leading;
  final Widget? trailing;

  const PremiumNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [AppElevation.shadowLg],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              if (leading != null) ...[
                const SizedBox(height: AppSpacing.md),
                leading!,
                const SizedBox(height: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == currentIndex;

                    return GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: AppIconTokens.md,
                              ),
                              if (isSelected) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.label,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(height: AppSpacing.md),
                trailing!,
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumNavigationRailItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  PremiumNavigationRailItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
