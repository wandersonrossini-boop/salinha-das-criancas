import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/radius.dart';
import '../design_system/spacing.dart';
import '../design_system/animations.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.isLoading = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: DsAnimations.fast,
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _isPressed = true;
    _scaleController.reverse();
    setState(() {});
  }

  void _onTapUp(TapUpDetails details) {
    _isPressed = false;
    _scaleController.forward();
    setState(() {});
    widget.onPressed();
  }

  void _onTapCancel() {
    _isPressed = false;
    _scaleController.forward();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.color ?? DsColors.primaryBlue;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ScaleTransition(
          scale: _scaleController,
          child: AnimatedContainer(
            duration: DsAnimations.fast,
            curve: DsAnimations.smooth,
            padding: const EdgeInsets.symmetric(
              vertical: DsSpacing.s20,
              horizontal: DsSpacing.s32,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: DsRadius.large,
              boxShadow: [
                if (_isHovered || _isPressed)
                  BoxShadow(
                    color: bgColor.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                else ...[
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 24),
                    const SizedBox(width: DsSpacing.s12),
                  ],
                  Text(
                    widget.label,
                    style: DsTypography.buttonText,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
