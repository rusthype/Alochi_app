import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class OnboardingPageIndicator extends StatelessWidget {
  final int activeIndex;
  final int totalPages;

  const OnboardingPageIndicator({
    super.key,
    required this.activeIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.brand : AppColors.brandSoft,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
