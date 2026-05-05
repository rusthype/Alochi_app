import 'package:flutter/material.dart';
import '../../theme/colors.dart';

enum AlochiStatusDotVariant { online, warning, offline }

class AlochiStatusDot extends StatelessWidget {
  final AlochiStatusDotVariant variant;
  final double size;

  const AlochiStatusDot({
    super.key,
    this.variant = AlochiStatusDotVariant.online,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (variant) {
      case AlochiStatusDotVariant.online:
        color = AppColors.success;
        break;
      case AlochiStatusDotVariant.warning:
        color = AppColors.warning;
        break;
      case AlochiStatusDotVariant.offline:
        color = AppColors.danger;
        break;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
