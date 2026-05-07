import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import 'alochi_button.dart';

class AlochiEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;

  // Backward compatibility aliases
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  const AlochiEmptyState({
    this.icon = Icons.hourglass_empty_rounded,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconSize = 64,
    this.ctaLabel,
    this.onCtaPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveActionLabel = actionLabel ?? ctaLabel;
    final effectiveOnAction = onAction ?? onCtaPressed;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize + AppSpacing.xl,
              height: iconSize + AppSpacing.xl,
              decoration: const BoxDecoration(
                color: AppColors.brandSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? AppColors.brand,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              title,
              style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                subtitle!,
                style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (effectiveActionLabel != null && effectiveOnAction != null) ...[
              const SizedBox(height: AppSpacing.l),
              AlochiButton.secondary(
                label: effectiveActionLabel,
                onPressed: effectiveOnAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
