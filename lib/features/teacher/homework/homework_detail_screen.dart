import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../../shared/widgets/alochi_pill.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/api/teacher_api.dart';
import 'homework_provider.dart';
import '../dashboard/dashboard_provider.dart';

class HomeworkDetailScreen extends ConsumerWidget {
  final String hwId;

  const HomeworkDetailScreen({super.key, required this.hwId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hwAsync = ref.watch(homeworkDetailProvider(hwId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AlochiAppBar(title: 'Vazifa'),
      body: hwAsync.when(
        data: (hw) => _HomeworkDetailBody(hw: hw, hwId: hwId),
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

class _HomeworkDetailBody extends ConsumerStatefulWidget {
  final HomeworkModel hw;
  final String hwId;

  const _HomeworkDetailBody({required this.hw, required this.hwId});

  @override
  ConsumerState<_HomeworkDetailBody> createState() =>
      _HomeworkDetailBodyState();
}

class _HomeworkDetailBodyState extends ConsumerState<_HomeworkDetailBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _sendingReminder = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HwHeader(hw: widget.hw),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.brand,
          unselectedLabelColor: AppColors.brandMuted,
          indicatorColor: AppColors.brand,
          indicatorWeight: 2,
          labelStyle:
              AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTextStyles.label,
          tabs: const [
            Tab(text: 'Topshiriqlar'),
            Tab(text: 'Eslatmalar'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Responses tab
              _ResponsesTab(hw: widget.hw),
              // Reminders tab
              _RemindersTab(
                hw: widget.hw,
                isSending: _sendingReminder,
                onSendReminder: _sendReminder,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendReminder() async {
    setState(() => _sendingReminder = true);
    try {
      final api = ref.read(teacherApiProvider);
      await api.sendHomeworkReminder(widget.hwId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eslatma yuborildi'),
          backgroundColor: Color(0xFF0F9A6E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingReminder = false);
    }
  }
}

class _HwHeader extends StatelessWidget {
  final HomeworkModel hw;

  const _HwHeader({required this.hw});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  hw.title,
                  style: AppTextStyles.titleL.copyWith(color: AppColors.ink),
                ),
              ),
              AlochiPill(
                label: hw.isActive ? 'Aktiv' : 'Tugagan',
                variant: hw.isActive
                    ? AlochiPillVariant.success
                    : AlochiPillVariant.neutral,
              ),
            ],
          ),
          if (hw.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              hw.description,
              style:
                  AppTextStyles.body.copyWith(color: AppColors.brandMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.m,
            children: [
              if (hw.groupName.isNotEmpty)
                _InfoBadge(
                    icon: Icons.group_outlined, label: hw.groupName),
              if (hw.subject.isNotEmpty)
                _InfoBadge(icon: Icons.book_outlined, label: hw.subject),
              if (hw.deadline.isNotEmpty)
                _InfoBadge(
                  icon: Icons.schedule_outlined,
                  label: _formatDate(hw.deadline),
                  color: hw.isActive
                      ? AppColors.brandMuted
                      : AppColors.danger,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoBadge({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brandMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodyS.copyWith(color: c)),
      ],
    );
  }
}

class _ResponsesTab extends StatelessWidget {
  final HomeworkModel hw;

  const _ResponsesTab({required this.hw});

  @override
  Widget build(BuildContext context) {
    if (hw.responseCount == 0) {
      return const AlochiEmptyState(
        title: 'Javob yo\'q',
        subtitle: "Hali hech bir o'quvchi topshirmagan",
      );
    }
    // Backend does not return individual responses in detail endpoint yet
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_turned_in_outlined,
                size: 48, color: AppColors.brand),
            const SizedBox(height: AppSpacing.m),
            Text(
              '${hw.responseCount} ta javob',
              style:
                  AppTextStyles.titleM.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              "O'quvchi javobi tafsilotlari V1.2 da",
              style: AppTextStyles.bodyS
                  .copyWith(color: AppColors.brandMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemindersTab extends StatelessWidget {
  final HomeworkModel hw;
  final bool isSending;
  final VoidCallback onSendReminder;

  const _RemindersTab({
    required this.hw,
    required this.isSending,
    required this.onSendReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        children: [
          AlochiCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(AppRadii.s),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: AppColors.brand, size: 20),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eslatma yuborish',
                        style: AppTextStyles.titleM
                            .copyWith(color: AppColors.ink),
                      ),
                      Text(
                        "Barcha topshirmagan o'quvchilarga",
                        style: AppTextStyles.bodyS
                            .copyWith(color: AppColors.brandMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          AlochiButton.primary(
            label: 'Eslatma yuborish',
            icon: Icons.send_rounded,
            isLoading: isSending,
            onPressed: hw.isActive ? onSendReminder : null,
          ),
          if (!hw.isActive) ...[
            const SizedBox(height: AppSpacing.m),
            Text(
              'Vazifa muddati tugagan — eslatma yuborib bo\'lmaydi',
              style: AppTextStyles.bodyS
                  .copyWith(color: AppColors.brandMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
