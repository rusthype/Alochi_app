import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/student_model.dart';
import '../attendance/attendance_provider.dart';
import '../dashboard/dashboard_provider.dart';
import '../groups/groups_provider.dart';

class GradesEntryScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  final String subject;

  const GradesEntryScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.subject,
  });

  @override
  ConsumerState<GradesEntryScreen> createState() => _GradesEntryScreenState();
}

class _GradesEntryScreenState extends ConsumerState<GradesEntryScreen> {
  final _topicController = TextEditingController();
  final Map<String, int> _grades = {};

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  double get _averageGrade {
    if (_grades.isEmpty) return 0;
    final sum = _grades.values.fold(0, (prev, e) => prev + e);
    return sum / _grades.length;
  }

  @override
  Widget build(BuildContext context) {
    final today = _todayString();
    final attKey = (classId: widget.groupId, date: today);
    final attAsync = ref.watch(attendanceMarkingProvider(attKey));

    return Scaffold(
      appBar: const AlochiAppBar(title: 'Baho qo\'yish'),
      body: Column(
        children: [
          _TopicHeader(
            groupName: widget.groupName,
            subject: widget.subject,
            controller: _topicController,
            avgGrade: _averageGrade,
          ),
          Expanded(
            child: _buildStudentList(attAsync),
          ),
          _BottomAction(
            onSave: _save,
            isEnabled: _grades.isNotEmpty && !_isSaving,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(AsyncValue<AttendanceMarkingState> attAsync) {
    // If attendance taken → show present+late only
    // If attendance not taken → load all group students from attendance endpoint
    return attAsync.when(
      data: (state) {
        final hasAttendance = state.markedCount > 0;
        final students = hasAttendance
            ? state.students.where((s) {
                final st = state.statuses[s.id];
                return st == AttendanceStatus.present ||
                    st == AttendanceStatus.late;
              }).toList()
            : state.students; // show all if no attendance taken

        if (students.isEmpty) {
          return Consumer(builder: (ctx, ref, _) {
            final allAsync = ref.watch(groupStudentsProvider(widget.groupId));
            return allAsync.when(
              data: (all) => all.isEmpty
                  ? const Center(child: Text("O'quvchilar yo'q"))
                  : _studentList(all),
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.brand)),
              error: (_, __) =>
                  const Center(child: Text("O'quvchilar yuklanmadi")),
            );
          });
        }
        return _studentList(students);
      },
      loading: () => Consumer(builder: (ctx, ref, _) {
        final allAsync = ref.watch(groupStudentsProvider(widget.groupId));
        return allAsync.when(
          data: (all) => _studentList(all),
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.brand)),
          error: (_, __) => const Center(child: Text("Yuklanmadi")),
        );
      }),
      error: (err, _) => Consumer(builder: (ctx, ref, _) {
        final allAsync = ref.watch(groupStudentsProvider(widget.groupId));
        return allAsync.when(
          data: (all) => _studentList(all),
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.brand)),
          error: (_, __) => const Center(child: Text("Yuklanmadi")),
        );
      }),
    );
  }

  Widget _studentList(List<StudentModel> students) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        return _GradeEntryRow(
          student: s,
          grade: _grades[s.id] ?? 0,
          onChanged: (val) => setState(() => _grades[s.id] = val),
        );
      },
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final api = ref.read(teacherApiProvider);
    final today = _todayString();
    final errors = <String>[];

    for (final entry in _grades.entries) {
      if (entry.value == 0) continue;
      try {
        await api.setGrade(
          studentId: entry.key,
          grade: entry.value,
          date: today,
          groupId: widget.groupId,
          subject: widget.subject.isNotEmpty ? widget.subject : 'Matematika',
        );
      } catch (e) {
        errors.add(e.toString());
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_grades.values.where((v) => v > 0).length} ta baho saqlandi'),
          backgroundColor: const Color(0xFF0F9A6E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xato: ${errors.first}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _TopicHeader extends StatelessWidget {
  final String groupName;
  final String subject;
  final TextEditingController controller;
  final double avgGrade;

  const _TopicHeader({
    required this.groupName,
    required this.subject,
    required this.controller,
    required this.avgGrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(groupName,
                        style: AppTextStyles.titleM.copyWith(
                            color: Theme.of(context).colorScheme.onSurface)),
                    Text(subject,
                        style: AppTextStyles.bodyS
                            .copyWith(color: AppColors.brandMuted)),
                  ],
                ),
              ),
              if (avgGrade > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(avgGrade.toStringAsFixed(1),
                        style: AppTextStyles.titleL
                            .copyWith(color: AppColors.brand)),
                    Text('O\'rtacha',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.brandMuted)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Mavzu sarlavhasini yozing...',
              hintStyle:
                  AppTextStyles.body.copyWith(color: AppColors.brandMuted),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.m),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeEntryRow extends StatelessWidget {
  final StudentModel student;
  final int grade;
  final ValueChanged<int> onChanged;

  const _GradeEntryRow({
    required this.student,
    required this.grade,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: AlochiCard(
        child: Row(
          children: [
            AlochiAvatar(name: student.fullName, size: 40),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(student.fullName,
                  style: AppTextStyles.titleM.copyWith(fontSize: 14)),
            ),
            _GradeButtonsRow(value: grade, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _GradeButtonsRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _GradeButtonsRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const grades = [2, 3, 4, 5];
    return Row(
      children: grades.map((g) {
        final isSelected = value == g;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(
            onTap: () => onChanged(isSelected ? 0 : g),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? _gradeColor(g) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '$g',
                style: AppTextStyles.label.copyWith(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                ),
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

class _BottomAction extends StatelessWidget {
  final VoidCallback onSave;
  final bool isEnabled;

  const _BottomAction({required this.onSave, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.l,
        right: AppSpacing.l,
        top: AppSpacing.m,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.m,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: AlochiButton.primary(
        label: 'Baholarni saqlash',
        onPressed: isEnabled ? onSave : null,
      ),
    );
  }
}
