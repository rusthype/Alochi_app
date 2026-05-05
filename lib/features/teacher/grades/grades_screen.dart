import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/api/teacher_api.dart';
import 'grades_provider.dart';

class GradesScreen extends ConsumerWidget {
  final String groupId;
  final String groupName;
  final String subject;

  const GradesScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.subject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(gradesJournalProvider(groupId));
    final today = _todayString();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AlochiAppBar(
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Baholar',
              style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
            ),
            Text(
              '$groupName · $subject',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
            ),
          ],
        ),
      ),
      body: gradesAsync.when(
        data: (data) => _GradesBody(
          data: data,
          groupId: groupId,
          subject: subject,
          today: today,
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

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class _GradesBody extends ConsumerWidget {
  final GradesJournalData data;
  final String groupId;
  final String subject;
  final String today;

  const _GradesBody({
    required this.data,
    required this.groupId,
    required this.subject,
    required this.today,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (groupId: groupId, subject: subject, date: today);
    final editState = ref.watch(gradeEditProvider(key));
    final notifier = ref.read(gradeEditProvider(key).notifier);

    // Listen for success/error
    ref.listen<GradeEditState>(gradeEditProvider(key), (prev, next) {
      if (next.savedSuccessfully && !(prev?.savedSuccessfully ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Baholar saqlandi'),
            backgroundColor: Color(0xFF0F9A6E),
          ),
        );
        ref.invalidate(gradesJournalProvider(groupId));
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    if (data.students.isEmpty) {
      return const AlochiEmptyState(
        title: 'Baholar yo\'q',
        subtitle: 'Bu guruh uchun hali baho kiritilmagan',
      );
    }

    return Column(
      children: [
        _DateHeader(today: today),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.m,
              AppSpacing.l,
              AppSpacing.xxl,
            ),
            itemCount: data.students.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.s),
            itemBuilder: (context, index) {
              final student = data.students[index];
              // Last journal grade for this student (most recent date)
              int? existingGrade;
              final studentJournal = data.journal[student.id];
              if (studentJournal != null && studentJournal.isNotEmpty) {
                final sortedDates = studentJournal.keys.toList()..sort();
                existingGrade = studentJournal[sortedDates.last];
              }
              final pendingGrade = editState.pending[student.id];
              return _GradeRow(
                student: student,
                existingGrade: existingGrade,
                pendingGrade: pendingGrade ?? 0,
                onGradeChanged: (g) => notifier.setGrade(student.id, g),
              );
            },
          ),
        ),
        _SaveBar(state: editState, onSave: notifier.saveAll),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String today;

  const _DateHeader({required this.today});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.m,
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 16, color: AppColors.brandMuted),
          const SizedBox(width: AppSpacing.s),
          Text(
            today,
            style: AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
          ),
          const SizedBox(width: AppSpacing.m),
          Text(
            'Bugungi baholar',
            style: AppTextStyles.label
                .copyWith(color: AppColors.brand, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  final GradeStudentRow student;
  final int? existingGrade;
  final int pendingGrade;
  final ValueChanged<int> onGradeChanged;

  const _GradeRow({
    required this.student,
    required this.existingGrade,
    required this.pendingGrade,
    required this.onGradeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayGrade = pendingGrade > 0 ? pendingGrade : (existingGrade ?? 0);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(
          color: pendingGrade > 0
              ? AppColors.brandLight
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          AlochiAvatar(name: student.name, size: 36),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(
              student.name,
              style: AppTextStyles.body.copyWith(color: AppColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _GradeSegmented(
            value: displayGrade,
            onChanged: onGradeChanged,
          ),
        ],
      ),
    );
  }
}

class _GradeSegmented extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _GradeSegmented({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const grades = [2, 3, 4, 5];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: grades.map((g) {
        final isSelected = value == g;
        Color bgColor;
        Color fgColor;
        if (isSelected) {
          bgColor = _gradeColor(g);
          fgColor = Colors.white;
        } else {
          bgColor = const Color(0xFFF3F4F6);
          fgColor = const Color(0xFF6B7280);
        }
        return GestureDetector(
          onTap: () => onChanged(isSelected ? 0 : g),
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadii.s),
            ),
            alignment: Alignment.center,
            child: Text(
              '$g',
              style: AppTextStyles.label.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _gradeColor(int grade) {
    switch (grade) {
      case 5:
        return const Color(0xFF0F9A6E);
      case 4:
        return AppColors.brand;
      case 3:
        return const Color(0xFFD97706);
      case 2:
        return AppColors.danger;
      default:
        return AppColors.brandMuted;
    }
  }
}

class _SaveBar extends StatelessWidget {
  final GradeEditState state;
  final Future<void> Function() onSave;

  const _SaveBar({required this.state, required this.onSave});

  @override
  Widget build(BuildContext context) {
    if (!state.hasChanges && !state.isSaving) return const SizedBox.shrink();

    final count = state.pending.values.where((g) => g > 0).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.xl),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: ElevatedButton(
        onPressed: state.isSaving ? null : () => onSave(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
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
                'Saqlash  ($count ta baho)',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
      ),
    );
  }
}
