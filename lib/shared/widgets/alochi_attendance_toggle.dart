import 'package:flutter/material.dart';
import '../../core/models/attendance_model.dart';

class AlochiAttendanceToggle extends StatelessWidget {
  final AttendanceStatus value;
  final ValueChanged<AttendanceStatus> onChanged;
  final double size;

  const AlochiAttendanceToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleButton(
          icon: Icons.check,
          activeColor: const Color(0xFF0F9A6E),
          isActive: value == AttendanceStatus.present,
          size: size,
          onTap: () => onChanged(AttendanceStatus.present),
        ),
        const SizedBox(width: 6),
        _ToggleButton(
          icon: Icons.remove,
          activeColor: const Color(0xFFD97706),
          isActive: value == AttendanceStatus.late,
          size: size,
          onTap: () => onChanged(AttendanceStatus.late),
        ),
        const SizedBox(width: 6),
        _ToggleButton(
          icon: Icons.close,
          activeColor: const Color(0xFFDC2626),
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
  final bool isActive;
  final double size;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.activeColor,
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
          color: isActive ? activeColor : const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? Colors.white : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}
