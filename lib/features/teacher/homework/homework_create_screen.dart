import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_input.dart';
import '../../../core/models/group_model.dart';
import '../../../core/utils/validators.dart';
import '../groups/groups_provider.dart';
import 'homework_provider.dart';

class HomeworkCreateScreen extends ConsumerStatefulWidget {
  final String? preselectedGroupId;

  const HomeworkCreateScreen({super.key, this.preselectedGroupId});

  @override
  ConsumerState<HomeworkCreateScreen> createState() =>
      _HomeworkCreateScreenState();
}

class _HomeworkCreateScreenState extends ConsumerState<HomeworkCreateScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.preselectedGroupId != null) {
      _selectedGroupId = widget.preselectedGroupId;
    }
  }

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedGroupId;
  DateTime? _deadline;

  // Toggles
  bool _telegramPoll = true;
  bool _reminder = true;
  bool _autoTrack = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsListProvider);
    final createStatus = ref.watch(homeworkCreateProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AlochiAppBar(title: 'Yangi vazifa'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AlochiInput(
                controller: _titleController,
                label: 'Sarlavha',
                hintText: 'Vazifa sarlavhasi...',
                validator: Validators.compose([
                  (v) => Validators.required(v, fieldName: 'Sarlavha'),
                  Validators.minLength(3, fieldName: 'Sarlavha'),
                  Validators.maxLength(100, fieldName: 'Sarlavha'),
                ]),
              ),
              const SizedBox(height: AppSpacing.m),
              _MultilineInput(
                controller: _descController,
                label: 'Tavsif',
                hintText: "Vazifa haqida batafsil yozing...",
                validator: Validators.compose([
                  (v) => Validators.required(v, fieldName: 'Tavsif'),
                  Validators.minLength(10, fieldName: 'Tavsif'),
                ]),
              ),
              const SizedBox(height: AppSpacing.m),

              // Group selector
              groupsAsync.when(
                data: (groups) => _GroupDropdown(
                  groups: groups,
                  selectedId: _selectedGroupId,
                  onChanged: (id) => setState(() => _selectedGroupId = id),
                ),
                loading: () => const _FieldSkeleton(label: 'Guruh'),
                error: (_, __) => const _FieldSkeleton(label: 'Guruh'),
              ),
              const SizedBox(height: AppSpacing.m),

              _DeadlinePicker(
                value: _deadline,
                onChanged: (dt) => setState(() => _deadline = dt),
              ),
              const SizedBox(height: AppSpacing.m),

              _QuickDeadlineChips(
                onSelected: (days) {
                  setState(() {
                    _deadline = DateTime.now().add(Duration(days: days));
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(
                'Sozlamalar',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.brandMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              _ToggleRow(
                icon: Icons.telegram_rounded,
                iconColor: const Color(0xFF0088CC),
                label: 'Telegram so\'rovnoma',
                value: _telegramPoll,
                onChanged: (v) => setState(() => _telegramPoll = v),
              ),
              _ToggleRow(
                icon: Icons.notifications_active_outlined,
                iconColor: AppColors.brand,
                label: 'Ota-onalarga eslatma',
                value: _reminder,
                onChanged: (v) => setState(() => _reminder = v),
              ),
              _ToggleRow(
                icon: Icons.auto_graph_rounded,
                iconColor: const Color(0xFF0F9A6E),
                label: 'Avtomatik kuzatuv',
                value: _autoTrack,
                onChanged: (v) => setState(() => _autoTrack = v),
              ),

              const SizedBox(height: AppSpacing.xxl),
              AlochiButton.primary(
                label: 'Yaratish',
                icon: Icons.add_rounded,
                isLoading: createStatus.isLoading,
                onPressed: createStatus.isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedGroupId == null) {
      _showError('Guruh tanlang');
      return;
    }

    if (_deadline == null) {
      _showError('Muddat tanlang');
      return;
    }

    final dueDateStr =
        '${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}';

    await ref.read(homeworkCreateProvider.notifier).create(
          groupId: _selectedGroupId!,
          title: _titleController.text,
          description: _descController.text,
          dueDate: dueDateStr,
        );

    final result = ref.read(homeworkCreateProvider);
    if (result.hasError) {
      _showError(result.error.toString());
    } else if (result.hasValue && result.value != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vazifa yaratildi'),
          backgroundColor: Color(0xFF0F9A6E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _QuickDeadlineChips extends StatelessWidget {
  final ValueChanged<int> onSelected;

  const _QuickDeadlineChips({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = [
      (label: 'Bugun', days: 0),
      (label: 'Erta', days: 1),
      (label: '3 kun', days: 3),
      (label: '1 hafta', days: 7),
    ];

    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        return ActionChip(
          label: Text(opt.label),
          labelStyle: AppTextStyles.caption.copyWith(color: AppColors.ink),
          backgroundColor: const Color(0xFFF3F4F6),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.s)),
          onPressed: () => onSelected(opt.days),
        );
      }).toList(),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(color: AppColors.ink),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.brand,
          ),
        ],
      ),
    );
  }
}

class _GroupDropdown extends StatelessWidget {
  final List<GroupModel> groups;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _GroupDropdown({
    required this.groups,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guruh',
          style: AppTextStyles.label.copyWith(
            color: AppColors.brandMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.m),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: selectedId,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.m,
              ),
              border: InputBorder.none,
            ),
            hint: Text(
              'Guruhni tanlang',
              style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
            ),
            items: groups
                .map((g) => DropdownMenuItem<String>(
                      value: g.id,
                      child: Text(
                        '${g.code} · ${g.subjectName}',
                        style:
                            AppTextStyles.body.copyWith(color: AppColors.ink),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _DeadlinePicker extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const _DeadlinePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Muddat',
          style: AppTextStyles.label.copyWith(
            color: AppColors.brandMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              locale: const Locale('uz', 'UZ'),
              helpText: 'Muddat tanlang',
              cancelText: 'Bekor qilish',
              confirmText: 'Tasdiqlash',
              builder: (ctx, child) {
                return Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: Theme.of(ctx).colorScheme.copyWith(
                          primary: AppColors.brand,
                        ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.m,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.m),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined,
                    size: 18, color: AppColors.brandMuted),
                const SizedBox(width: AppSpacing.s),
                Text(
                  value != null
                      ? '${value!.day.toString().padLeft(2, '0')}.${value!.month.toString().padLeft(2, '0')}.${value!.year}'
                      : 'Sanani tanlang',
                  style: AppTextStyles.body.copyWith(
                    color: value != null ? AppColors.ink : AppColors.brandMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MultilineInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? Function(String?)? validator;

  const _MultilineInput({
    required this.controller,
    required this.label,
    required this.hintText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColors.brandMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        TextFormField(
          controller: controller,
          maxLines: 4,
          validator: validator,
          style: AppTextStyles.body.copyWith(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(AppSpacing.m),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
              borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldSkeleton extends StatelessWidget {
  final String label;

  const _FieldSkeleton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: AppColors.brandMuted),
        ),
        const SizedBox(height: AppSpacing.s),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
        ),
      ],
    );
  }
}
