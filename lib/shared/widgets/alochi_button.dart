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

class AlochiButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
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

    if (isDisabled && variant != AlochiButtonVariant.ghost && variant != AlochiButtonVariant.secondary) {
      backgroundColor = backgroundColor.withOpacity(0.5);
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.m),
            side: borderSide,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor.withOpacity(0.6),
        ),
        child: isLoading
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
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.button.copyWith(color: foregroundColor),
                  ),
                ],
              ),
      ),
    );
  }
}
