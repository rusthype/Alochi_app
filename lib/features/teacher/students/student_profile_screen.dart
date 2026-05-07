import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_pill.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../shared/widgets/alochi_skeleton.dart';
import '../../../core/models/student_model.dart';
import 'student_provider.dart';

class StudentProfileScreen extends ConsumerWidget {
  final String studentId;

  const StudentProfileScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProfileProvider(studentId));

    return Scaffold(
      appBar: AlochiAppBar(
        title: '',
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz_rounded,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentProfileProvider(studentId));
          await ref.read(studentProfileProvider(studentId).future);
        },
        color: AppColors.brand,
        child: studentAsync.when(
          data: (student) => _StudentProfileBody(student: student),
          loading: () => const _StudentProfileSkeleton(),
          error: (err, _) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: AlochiEmptyState(
                title: "Ma'lumot topilmadi",
                subtitle: err.toString(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentProfileSkeleton extends StatelessWidget {
  const _StudentProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: const [
        Center(
            child: AlochiSkeleton(
                height: 84,
                width: 84,
                borderRadius: BorderRadius.all(Radius.circular(100)))),
        SizedBox(height: AppSpacing.m),
        Center(child: AlochiSkeleton(width: 200, height: 24)),
        SizedBox(height: AppSpacing.s),
        Center(child: AlochiSkeleton(width: 150, height: 16)),
        SizedBox(height: AppSpacing.l),
        Row(
          children: [
            Expanded(child: AlochiSkeletonCard(height: 80)),
            SizedBox(width: 10),
            Expanded(child: AlochiSkeletonCard(height: 80)),
            SizedBox(width: 10),
            Expanded(child: AlochiSkeletonCard(height: 80)),
          ],
        ),
        SizedBox(height: AppSpacing.l),
        AlochiSkeletonCard(height: 120),
        SizedBox(height: AppSpacing.l),
        AlochiSkeletonCard(height: 100),
      ],
    );
  }
}

class _StudentProfileBody extends StatefulWidget {
  final StudentModel student;

  const _StudentProfileBody({required this.student});

  @override
  State<_StudentProfileBody> createState() => _StudentProfileBodyState();
}

class _StudentProfileBodyState extends State<_StudentProfileBody> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isBirthdayToday()) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  bool _isBirthdayToday() {
    if (widget.student.birthday == null) return false;
    try {
      final birthday = DateTime.parse(widget.student.birthday!);
      final now = DateTime.now();
      return birthday.day == now.day && birthday.month == now.month;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isBirthdayToday()) _BirthdayBanner(student: widget.student),
              _HeroSection(student: widget.student),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.m),
                    _ThreeStatTiles(student: widget.student),
                    const SizedBox(height: 16),
                    _TodayActivityCard(student: widget.student),
                    const SizedBox(height: 24),
                    if (widget.student.parents.isNotEmpty) ...[
                      _ParentContactSection(parents: widget.student.parents),
                      const SizedBox(height: 24),
                    ],
                    _AttendanceCalendarSection(
                        days: widget.student.recentAttendance),
                    const SizedBox(height: 24),
                    _TeacherNotesSection(student: widget.student),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppColors.brand,
              AppColors.accent,
              AppColors.success,
              AppColors.warning,
              Colors.blue,
              Colors.pink,
            ],
          ),
        ),
      ],
    );
  }
}

class _BirthdayBanner extends StatelessWidget {
  final StudentModel student;

  const _BirthdayBanner({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.1),
        border: const Border(
          bottom: BorderSide(color: AppColors.brand, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Text('🎂', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bugun ${student.firstName}ning tug'ilgan kuni!",
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
                Text(
                  "Ustoz sifatida tabriklashni unutmang!",
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              context.push(
                '/teacher/messages/compose',
                extra: {
                  'recipientId': student.id,
                  'recipientName': student.fullName,
                  'initialMessage':
                      "Assalomu alaykum, ${student.firstName}! Tug'ilgan kuningiz muborak bo'lsin! 🎂 Kelajakda ulkan zafarlar tilayman.",
                },
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tabriklash', style: TextStyle(fontSize: 12)),
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
    final nextLevelXp = student.level * 500;
    final currentLevelBase = (student.level - 1) * 500;
    final xpInCurrentLevel = student.xp - currentLevelBase;
    final progress = (xpInCurrentLevel / 500).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
      child: Column(
        children: [
          AlochiAvatar(name: student.fullName, size: 84),
          const SizedBox(height: 12),
          Text(
            student.fullName,
            style: AppTextStyles.displayM.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AlochiPill(
                  label: student.classId.isNotEmpty
                      ? '${student.classId} Guruh'
                      : student.schoolName ?? 'Guruh',
                  variant: AlochiPillVariant.brand),
              if (student.schoolName != null) ...[
                const SizedBox(width: 8),
                Text(
                  student.schoolName!,
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.gray),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // XP Progress
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _LevelBadge(level: student.level),
                  Text(
                    '${student.xp} / $nextLevelXp XP',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.brand),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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

class _LevelBadge extends StatelessWidget {
  final int level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    Color color = const Color(0xFF6B7280); // 1-3
    if (level >= 10) {
      color = AppColors.success;
    } else if (level >= 7) {
      color = AppColors.warning;
    } else if (level >= 4) {
      color = AppColors.brand;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$level-DARAJA',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TodayActivityCard extends StatelessWidget {
  final StudentModel student;

  const _TodayActivityCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final todayAtt = student.recentAttendance.firstWhere(
      (a) => a.date == dateStr,
      orElse: () => const AttendanceDayModel(date: '', status: 'no_lesson'),
    );

    final todayGrade = student.recentGrades.firstWhere(
      (g) => g.date == dateStr,
      orElse: () =>
          const RecentGradeModel(id: '', value: 0, topicTitle: '', date: ''),
    );

    final hasActivity = todayAtt.status != 'no_lesson' || todayGrade.value > 0;

    if (!hasActivity) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                "BUGUNGI FAOLLIK",
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gray2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (todayAtt.status != 'no_lesson')
                Expanded(
                  child: _ActivityItem(
                    label: 'Davomat',
                    value: _attLabel(todayAtt.status),
                    color: _attColor(todayAtt.status),
                  ),
                ),
              if (todayAtt.status != 'no_lesson' && todayGrade.value > 0)
                Container(
                  width: 1,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Theme.of(context).dividerColor,
                ),
              if (todayGrade.value > 0)
                Expanded(
                  child: _ActivityItem(
                    label: 'Baho',
                    value: '${todayGrade.value}',
                    color: _gradeColor(todayGrade.value),
                    subLabel: todayGrade.topicTitle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _attLabel(String status) {
    switch (status) {
      case 'present':
        return 'Keldi';
      case 'late':
        return 'Kech';
      case 'absent':
        return 'Kelmagan';
      default:
        return 'Noma\'lum';
    }
  }

  Color _attColor(String status) {
    switch (status) {
      case 'present':
        return AppColors.success;
      case 'late':
        return AppColors.warning;
      case 'absent':
        return AppColors.danger;
      default:
        return AppColors.gray;
    }
  }

  Color _gradeColor(int grade) {
    if (grade == 5) return AppColors.success;
    if (grade == 4) return AppColors.brand;
    if (grade == 3) return AppColors.warning;
    return AppColors.danger;
  }
}

class _ActivityItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? subLabel;

  const _ActivityItem({
    required this.label,
    required this.value,
    required this.color,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.gray),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: AppTextStyles.titleM.copyWith(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        if (subLabel != null)
          Text(
            subLabel!,
            style: const TextStyle(fontSize: 10, color: AppColors.gray2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
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
                    color: Theme.of(context).colorScheme.onSurface,
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        color: Theme.of(context).colorScheme.onSurface,
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
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
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Theme.of(context).cardColor,
                    title: Text('Izoh qo\'shish',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface)),
                    content: const TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Izohingizni yozing...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
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
