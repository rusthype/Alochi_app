import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_pill.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/models/student_model.dart';
import 'student_provider.dart';

class StudentProfileScreen extends ConsumerWidget {
  final String studentId;

  const StudentProfileScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProfileProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AlochiAppBar(
        title: '',
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: AppColors.ink),
            onPressed: () {},
          ),
        ],
      ),
      body: studentAsync.when(
        data: (student) => _StudentProfileBody(student: student),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (err, _) => AlochiEmptyState(
          title: "Ma'lumot topilmadi",
          subtitle: err.toString(),
        ),
      ),
    );
  }
}

class _StudentProfileBody extends StatelessWidget {
  final StudentModel student;

  const _StudentProfileBody({required this.student});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroSection(student: student),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.m),
                _ThreeStatTiles(student: student),
                const SizedBox(height: 24),
                if (student.parents.isNotEmpty) ...[
                  _ParentContactSection(parents: student.parents),
                  const SizedBox(height: 24),
                ],
                _AttendanceCalendarSection(days: student.recentAttendance),
                const SizedBox(height: 24),
                _TeacherNotesSection(student: student),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final StudentModel student;

  const _HeroSection({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
      child: Column(
        children: [
          AlochiAvatar(name: student.fullName, size: 84),
          const SizedBox(height: 12),
          Text(
            student.fullName,
            style: AppTextStyles.displayM.copyWith(
              color: AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AlochiPill(
                  label: '${student.classId} Guruh',
                  variant: AlochiPillVariant.brand),
              if (student.schoolName != null) ...[
                const SizedBox(width: 8),
                Text(
                  student.schoolName!,
                  style: AppTextStyles.bodyS
                      .copyWith(color: const Color(0xFF6B7280)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2EF),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              "★ ${student.xp} XP · ${student.level}-daraja",
              style: AppTextStyles.label.copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AlochiButton.primary(
                  label: "Ota-onaga yozish",
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AlochiButton.secondary(
                  label: "Eslatma yubor",
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThreeStatTiles extends StatelessWidget {
  final StudentModel student;

  const _ThreeStatTiles({required this.student});

  @override
  Widget build(BuildContext context) {
    final att = student.attendancePct ?? 0;
    final avg = student.avgGrade ?? 0;

    Color attColor = const Color(0xFF0F9A6E);
    if (att < 90) attColor = AppColors.brand;
    if (att < 75) attColor = const Color(0xFFD97706);

    return Row(
      children: [
        _StatTile(
          label: 'DAVOMAT',
          value: '${att.toStringAsFixed(0)}%',
          valueColor: attColor,
        ),
        const SizedBox(width: 10),
        _StatTile(
          label: "O'RTACHA",
          value: avg > 0 ? avg.toStringAsFixed(1) : '0.0',
          valueColor: avg < 4.0 ? const Color(0xFFD97706) : AppColors.brand,
        ),
        const SizedBox(width: 10),
        _StatTile(
          label: 'VAZIFA',
          value: '${student.missedLessons ?? 0}',
          valueColor: (student.missedLessons ?? 0) > 2
              ? AppColors.danger
              : AppColors.ink,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.titleL.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF9CA3AF),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentContactSection extends StatelessWidget {
  final List<ParentModel> parents;

  const _ParentContactSection({required this.parents});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "OTA-ONA KONTAKTI",
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        ...parents.map((p) => _ParentRow(parent: p)),
      ],
    );
  }
}

class _ParentRow extends StatelessWidget {
  final ParentModel parent;

  const _ParentRow({required this.parent});

  @override
  Widget build(BuildContext context) {
    final isFather = parent.relation == 'father';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                isFather ? const Color(0xFFE8F2EF) : const Color(0xFFFCEBEB),
            child: Icon(
              isFather ? Icons.person_rounded : Icons.person_3_rounded,
              size: 18,
              color: isFather ? AppColors.brand : const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFather ? "Otasi" : "Onasi",
                  style: AppTextStyles.caption
                      .copyWith(color: const Color(0xFF6B7280)),
                ),
                Text(
                  parent.name,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _ActionButton(
            icon: Icons.send_rounded,
            color: parent.telegramLinked
                ? const Color(0xFF26A5E4)
                : const Color(0xFF9CA3AF),
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.phone_enabled_rounded,
            color: const Color(0xFF6B7280),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _AttendanceCalendarSection extends StatelessWidget {
  final List<AttendanceDayModel> days;

  const _AttendanceCalendarSection({required this.days});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SO'NGGI 14 KUN DAVOMAT",
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: days.map((day) {
              return Container(
                width: 44,
                height: 36,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: _statusColor(day.status),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayFromDate(day.date),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      _monthFromDate(day.date),
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 8,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        if (days.isEmpty)
          Text(
            "Ma'lumot mavjud emas",
            style: AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
          ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return const Color(0xFFE1F5EE);
      case 'late':
        return const Color(0xFFFEF3C7);
      case 'absent':
        return const Color(0xFFFCEBEB);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  String _dayFromDate(String date) {
    try {
      return DateTime.parse(date).day.toString();
    } catch (_) {
      return '';
    }
  }

  String _monthFromDate(String date) {
    try {
      final months = [
        'YAN',
        'FEV',
        'MAR',
        'APR',
        'MAY',
        'IYUN',
        'IYUL',
        'AVG',
        'SEN',
        'OKT',
        'NOV',
        'DEK'
      ];
      return months[DateTime.parse(date).month - 1];
    } catch (_) {
      return '';
    }
  }
}

class _TeacherNotesSection extends StatelessWidget {
  final StudentModel student;

  const _TeacherNotesSection({required this.student});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "USTOZ IZOHI",
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "Faqat siz ko'rasiz",
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.notes ?? "O'quvchi haqida izoh yozilmagan.",
                style:
                    AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Izoh qo\'shish'),
                    content: const TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Izohingizni yozing...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Yopish'),
                      ),
                    ],
                  ),
                ),
                child: Text(
                  student.notes == null ? "+ Yozuv qo'shish" : "Tahrirlash",
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
