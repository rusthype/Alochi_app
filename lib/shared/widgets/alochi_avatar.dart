import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class AlochiAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;

  const AlochiAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
  });

  const AlochiAvatar.s({
    super.key,
    required this.name,
    this.imageUrl,
  }) : size = 28;

  const AlochiAvatar.m({
    super.key,
    required this.name,
    this.imageUrl,
  }) : size = 40;

  const AlochiAvatar.l({
    super.key,
    required this.name,
    this.imageUrl,
  }) : size = 64;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(imageUrl!),
            fit: BoxFit.cover,
          ),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
      );
    }

    final String initials = _getInitials(name);
    final Color backgroundColor = _getBackgroundColor(name);
    final Color foregroundColor = _getForegroundColor(backgroundColor);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.label.copyWith(
            color: foregroundColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getBackgroundColor(String name) {
    final int hash = name.hashCode;
    final List<Color> colors = [
      AppColors.brand,
      const Color(0xFF0F9A6E),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFF0EA5E9),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
    return colors[hash.abs() % colors.length];
  }

  Color _getForegroundColor(Color backgroundColor) {
    return Colors.white;
  }
}
