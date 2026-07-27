import 'dart:ui';
import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/radius.dart';
import '../../design_system/elevation.dart';
import '../../design_system/icon_tokens.dart';

class PremiumBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PremiumBottomNavigationItem> items;

  const PremiumBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.s12,
              vertical: DsSpacing.s12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == currentIndex;

                return GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DsSpacing.s16,
                      vertical: DsSpacing.s12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? item.color.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            key: ValueKey<bool>(isSelected),
                            color: isSelected ? item.color : const Color(0xFF94A3B8),
                            size: 24,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: DsSpacing.s8),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: item.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumBottomNavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  PremiumBottomNavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
