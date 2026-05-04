import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import 'alochi_button.dart';

class AlochiEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? illustrationPath;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  const AlochiEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.illustrationPath,
    this.ctaLabel,
    this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (illustrationPath != null) ...[
              if (illustrationPath!.endsWith('.svg'))
                SvgPicture.asset(
                  illustrationPath!,
                  height: 160,
                  placeholderBuilder: (context) => const SizedBox(height: 160),
                )
              else
                Image.asset(
                  illustrationPath!,
                  height: 160,
                ),
              const SizedBox(height: 24),
            ] else ...[
              const Icon(
                Icons.hourglass_empty_rounded,
                size: 80,
                color: Color(0xFFE5E7EB),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              title,
              style: AppTextStyles.titleL.copyWith(color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyles.body.copyWith(color: const Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
            ],
            if (ctaLabel != null && onCtaPressed != null) ...[
              const SizedBox(height: 32),
              AlochiButton.primary(
                label: ctaLabel!,
                onPressed: onCtaPressed,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
