import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/typography.dart';

enum AlochiPillVariant {
  brand,
  info,
  success,
  warning,
  danger,
  neutral,
}

class AlochiPill extends StatelessWidget {
  final String label;
  final AlochiPillVariant variant;

  const AlochiPill({
    super.key,
    required this.label,
    this.variant = AlochiPillVariant.brand,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;

    switch (variant) {
      case AlochiPillVariant.brand:
        backgroundColor = AppColors.brandSoft;
        foregroundColor = AppColors.brand;
        break;
      case AlochiPillVariant.info:
        backgroundColor = AppColors.info.withValues(alpha: 0.1);
        foregroundColor = AppColors.info;
        break;
      case AlochiPillVariant.success:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        foregroundColor = AppColors.success;
        break;
      case AlochiPillVariant.warning:
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        foregroundColor = AppColors.warning;
        break;
      case AlochiPillVariant.danger:
        backgroundColor = AppColors.danger.withValues(alpha: 0.1);
        foregroundColor = AppColors.danger;
        break;
      case AlochiPillVariant.neutral:
        backgroundColor = const Color(0xFFF3F4F6);
        foregroundColor = const Color(0xFF6B7280);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.round),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
