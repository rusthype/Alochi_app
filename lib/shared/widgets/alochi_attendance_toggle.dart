import 'package:flutter/material.dart';
import '../../core/models/attendance_model.dart';
import '../../theme/radii.dart';

class AlochiAttendanceToggle extends StatelessWidget {
  final AttendanceStatus value;
  final ValueChanged<AttendanceStatus> onChanged;
  final double size;

  const AlochiAttendanceToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleButton(
          icon: Icons.check,
          activeColor: const Color(0xFF0F9A6E),
          activeBg: const Color(0xFFE1F5EE),
          isActive: value == AttendanceStatus.present,
          size: size,
          onTap: () => onChanged(AttendanceStatus.present),
        ),
        const SizedBox(width: 4),
        _ToggleButton(
          icon: Icons.remove,
          activeColor: const Color(0xFFD97706),
          activeBg: const Color(0xFFFAEEDA),
          isActive: value == AttendanceStatus.late,
          size: size,
          onTap: () => onChanged(AttendanceStatus.late),
        ),
        const SizedBox(width: 4),
        _ToggleButton(
          icon: Icons.close,
          activeColor: const Color(0xFFDC2626),
          activeBg: const Color(0xFFFCEBEB),
          isActive: value == AttendanceStatus.absent,
          size: size,
          onTap: () => onChanged(AttendanceStatus.absent),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final Color activeColor;
  final Color activeBg;
  final bool isActive;
  final double size;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.activeColor,
    required this.activeBg,
    required this.isActive,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? activeBg : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(AppRadii.s),
          border: isActive
              ? Border.all(color: activeColor.withValues(alpha: 0.4), width: 1)
              : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(
          icon,
          size: size * 0.5,
          color: isActive ? activeColor : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}
