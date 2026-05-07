import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_attendance_toggle.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../shared/widgets/alochi_skeleton.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/student_model.dart';
import 'attendance_provider.dart';

class AttendanceMarkScreen extends ConsumerWidget {
  final String classId;
  final String date;
  final String groupName;

  const AttendanceMarkScreen({
    super.key,
    required this.classId,
    required this.date,
    this.groupName = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (classId: classId, date: date);
    final stateAsync = ref.watch(attendanceMarkingProvider(key));
    final notifier = ref.read(attendanceMarkingProvider(key).notifier);

    // Listen for save success and pop
    ref.listen<AsyncValue<AttendanceMarkingState>>(
      attendanceMarkingProvider(key),
      (previous, next) {
        final data = next.valueOrNull;
        if (data != null && data.savedSuccessfully) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Davomat saqlandi'),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(
                  AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.m),
              ),
            ),
          );
          if (context.canPop()) context.pop();
        }
        if (data != null && data.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data.error ?? 'Xatolik yuz berdi'),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(
                  AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.m),
              ),
            ),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AlochiAppBar(title: 'Davomat belgilash'),
      body: stateAsync.when(
        data: (state) => Column(
          children: [
            _ClassDatePills(classId: classId, date: date, groupName: groupName),
            _LiveStatsRow(state: state),
            if (state.unmarkedCount == state.students.length &&
                state.students.isNotEmpty)
              _AllPresentDashedCta(onPressed: notifier.markAllPresent),
            Expanded(
              child: state.students.isEmpty
                  ? const AlochiEmptyState(
                      title: "O'quvchilar yo'q",
                      subtitle: 'Bu guruhda hali o\'quvchi biriktirilmagan',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                        vertical: AppSpacing.s,
                      ),
                      itemCount: state.students.length,
                      itemBuilder: (context, index) {
                        final student = state.students[index];
                        return _StudentAttendanceRow(
                          student: student,
                          status: state.statuses[student.id] ??
                              AttendanceStatus.unmarked,
                          onChanged: (s) => notifier.setStatus(student.id, s),
                        );
                      },
                    ),
            ),
            _StickySaveButton(
              state: state,
              onSave: notifier.save,
            ),
          ],
        ),
        loading: () => const _AttendanceLoadingSkeleton(),
        error: (err, _) => Center(
          child: AlochiEmptyState(
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.danger,
            title: 'Yuklab bo\'lmadi',
            subtitle: 'Qayta urinib ko\'ring',
            actionLabel: 'Yangilash',
            onAction: () => ref.invalidate(attendanceMarkingProvider(key)),
          ),
        ),
      ),
    );
  }
}

class _AttendanceLoadingSkeleton extends StatelessWidget {
  const _AttendanceLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: const [
        AlochiSkeletonCard(height: 60),
        AlochiSkeletonCard(height: 60),
        AlochiSkeletonCard(height: 60),
        AlochiSkeletonCard(height: 60),
        AlochiSkeletonCard(height: 60),
      ],
    );
  }
}

class _ClassDatePills extends StatelessWidget {
  final String classId;
  final String date;
  final String groupName;

  const _ClassDatePills({
    required this.classId,
    required this.date,
    this.groupName = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.s),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(AppRadii.round),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    groupName.isNotEmpty
                        ? groupName
                        : (classId.length > 20 ? 'Guruh' : classId),
                    style: AppTextStyles.label.copyWith(
                        color: AppColors.brand, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: AppColors.brand),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(AppRadii.round),
            ),
            child: Text(
              date,
              style: AppTextStyles.label.copyWith(color: AppColors.brandMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveStatsRow extends StatelessWidget {
  final AttendanceMarkingState state;

  const _LiveStatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _StatTile(
            count: state.presentCount,
            label: 'KELDI',
            bgColor: const Color(0xFFE1F5EE),
            textColor: const Color(0xFF0F9A6E),
          ),
          const SizedBox(width: 8),
          _StatTile(
            count: state.lateCount,
            label: 'KECH',
            bgColor: const Color(0xFFFAEEDA),
            textColor: const Color(0xFFD97706),
          ),
          const SizedBox(width: 8),
          _StatTile(
            count: state.absentCount,
            label: "YO'Q",
            bgColor: const Color(0xFFFCEBEB),
            textColor: const Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          _StatTile(
            count: state.unmarkedCount,
            label: 'QOLDI',
            bgColor: const Color(0xFFF4F5F7),
            textColor: const Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final int count;
  final String label;
  final Color bgColor;
  final Color textColor;

  const _StatTile({
    required this.count,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: AppTextStyles.titleL.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: textColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllPresentDashedCta extends StatelessWidget {
  final VoidCallback onPressed;

  const _AllPresentDashedCta({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F2EF),
            borderRadius: BorderRadius.circular(12),
            // Custom dashed border simulation or solid if not available
            border: Border.all(
              color: AppColors.brand.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.brand, size: 20),
              const SizedBox(width: 8),
              Text(
                'Hammasi keldi',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentAttendanceRow extends StatelessWidget {
  final StudentModel student;
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;

  const _StudentAttendanceRow({
    required this.student,
    required this.status,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          AlochiAvatar(name: student.fullName, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              student.fullName,
              style: AppTextStyles.titleM.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AlochiAttendanceToggle(value: status, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _StickySaveButton extends StatelessWidget {
  final AttendanceMarkingState state;
  final Future<void> Function() onSave;

  const _StickySaveButton({required this.state, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final canSave = state.canSave;
    return Container(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 30),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: canSave && !state.isSaving ? onSave : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: state.isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Saqlash',
                    style: AppTextStyles.titleM,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${state.markedCount}/${state.students.length}',
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
