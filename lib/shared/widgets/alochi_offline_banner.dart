import 'package:flutter/material.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';

class AlochiOfflineBanner extends StatelessWidget {
  const AlochiOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade700,
      padding:
          const EdgeInsets.symmetric(vertical: 6, horizontal: AppSpacing.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: AppSpacing.s),
          Text(
            'Internet yo\'q · Saqlangan ma\'lumotlar ko\'rsatilmoqda',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
