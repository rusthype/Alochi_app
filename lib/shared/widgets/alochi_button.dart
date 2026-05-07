import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/typography.dart';

enum AlochiButtonVariant {
  primary,
  secondary,
  danger,
  telegram,
  ghost,
}

class AlochiButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AlochiButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AlochiButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AlochiButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  const AlochiButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : variant = AlochiButtonVariant.primary;

  const AlochiButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : variant = AlochiButtonVariant.secondary;

  const AlochiButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : variant = AlochiButtonVariant.danger;

  const AlochiButton.telegram({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : variant = AlochiButtonVariant.telegram;

  const AlochiButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  }) : variant = AlochiButtonVariant.ghost;

  @override
  State<AlochiButton> createState() => _AlochiButtonState();
}

class _AlochiButtonState extends State<AlochiButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (widget.variant) {
      case AlochiButtonVariant.primary:
        backgroundColor = AppColors.brand;
        foregroundColor = Colors.white;
        break;
      case AlochiButtonVariant.secondary:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.brand;
        borderSide = const BorderSide(color: AppColors.brand, width: 1.5);
        break;
      case AlochiButtonVariant.danger:
        backgroundColor = AppColors.danger;
        foregroundColor = Colors.white;
        break;
      case AlochiButtonVariant.telegram:
        backgroundColor = const Color(0xFF0088CC);
        foregroundColor = Colors.white;
        break;
      case AlochiButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.brandMuted;
        break;
    }

    if (isDisabled &&
        widget.variant != AlochiButtonVariant.ghost &&
        widget.variant != AlochiButtonVariant.secondary) {
      backgroundColor = backgroundColor.withValues(alpha: 0.5);
    }

    final content = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: AppTextStyles.button.copyWith(color: foregroundColor),
              ),
            ],
          );

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: 48,
      child: AnimatedScale(
        scale: _isPressed && !isDisabled ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadii.m),
          child: InkWell(
            onTap: isDisabled ? null : widget.onPressed,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(AppRadii.m),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return foregroundColor.withValues(alpha: 0.12);
              }
              if (states.contains(WidgetState.hovered)) {
                return foregroundColor.withValues(alpha: 0.04);
              }
              return null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.m),
                border: Border.fromBorderSide(borderSide),
              ),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}
