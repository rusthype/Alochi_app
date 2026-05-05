import 'package:flutter/material.dart';
import '../../theme/typography.dart';
import '../../theme/radii.dart';

class AlochiGradeBadge extends StatelessWidget {
  final int value;
  final double size;

  const AlochiGradeBadge({
    super.key,
    required this.value,
    this.size = 26,
  });

  Color _bgColor() {
    switch (value) {
      case 5:
        return const Color(0xFFE1F5EE);
      case 4:
        return const Color(0xFFFFF3E9);
      case 3:
        return const Color(0xFFFAEEDA);
      default:
        return const Color(0xFFFCEBEB);
    }
  }

  Color _fgColor() {
    switch (value) {
      case 5:
        return const Color(0xFF0F9A6E);
      case 4:
        return const Color(0xFFF97316);
      case 3:
        return const Color(0xFFD97706);
      default:
        return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      alignment: Alignment.center,
      child: Text(
        value.toString(),
        style: AppTextStyles.label.copyWith(
          color: _fgColor(),
          fontWeight: FontWeight.w700,
          fontSize: size * 0.5,
        ),
      ),
    );
  }
}
