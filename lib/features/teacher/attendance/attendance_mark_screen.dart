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
import '../../../core/models/attendance_model.dart';
import '../../../core/models/student_model.dart';
import 'attendance_provider.dart';

class AttendanceMarkScreen extends ConsumerWidget {
  final String classId;
  final String date;

  const AttendanceMarkScreen({
    super.key,
    required this.classId,
    required this.date,
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
            const SnackBar(
              content: Text('Davomat saqlandi'),
              backgroundColor: Color(0xFF0F9A6E),
            ),
          );
          if (context.canPop()) context.pop();
        }
        if (data != null && data.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data.error ?? 'Xatolik yuz berdi'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AlochiAppBar(title: 'Davomat belgilash'),
      body: stateAsync.when(
        data: (state) => Column(
          children: [
            _ClassDatePills(classId: classId, date: date),
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (err, _) => AlochiEmptyState(
          title: 'Yuklab bo\'lmadi',
          subtitle: err.toString(),
        ),
      ),
    );
  }
}

class _ClassDatePills extends StatelessWidget {
  final String classId;
  final String date;

  const _ClassDatePills({required this.classId, required this.date});

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
                Text(classId,
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.brand, fontWeight: FontWeight.w600)),
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
              style: AppTextStyles.label
                  .copyWith(color: AppColors.brandMuted),
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
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l, vertical: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatPill(
              count: state.presentCount,
              label: 'Keldi',
              color: const Color(0xFF0F9A6E)),
          _StatPill(
              count: state.lateCount,
              label: 'Kech',
              color: const Color(0xFFD97706)),
          _StatPill(
              count: state.absentCount,
              label: "Yo'q",
              color: AppColors.danger),
          _StatPill(
              count: state.unmarkedCount,
              label: 'Belgilanmagan',
              color: AppColors.brandMuted),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatPill(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: AppTextStyles.titleM.copyWith(color: color),
        ),
        Text(
          label,
          style:
              AppTextStyles.caption.copyWith(color: AppColors.brandMuted),
        ),
      ],
    );
  }
}

class _AllPresentDashedCta extends StatelessWidget {
  final VoidCallback onPressed;

  const _AllPresentDashedCta({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l, vertical: AppSpacing.s),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.l),
            border: Border.all(
              color: AppColors.brand,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.brand, size: 18),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Hammasi keldi',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.brand, fontWeight: FontWeight.w600),
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
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m, vertical: AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          AlochiAvatar(name: student.fullName, size: 36),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(
              student.fullName,
              style: AppTextStyles.body.copyWith(color: AppColors.ink),
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
    if (!state.hasUnsavedChanges) return const SizedBox.shrink();

    final canSave = state.canSave;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.xl),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: ElevatedButton(
        onPressed: canSave && !state.isSaving
            ? () => onSave()
            : state.unmarkedCount > 0
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${state.unmarkedCount} ta o\'quvchi belgilanmagan',
                        ),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  }
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canSave ? AppColors.brand : AppColors.brandTint,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
        ),
        child: state.isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                'Saqlash  ${state.markedCount}/${state.students.length}',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
      ),
    );
  }
}
