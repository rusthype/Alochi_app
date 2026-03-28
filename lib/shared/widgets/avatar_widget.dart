import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AvatarWidget extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const AvatarWidget({
    super.key,
    required this.name,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? avatarColor(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: TextStyle(
            color: c,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
