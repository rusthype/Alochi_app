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
      appBar: const AlochiAppBar(title: 'Vazifa'),
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
        _StatsHero(stats: widget.hw.stats),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.brand,
          unselectedLabelColor: AppColors.brandMuted,
          indicatorColor: AppColors.brand,
          indicatorWeight: 2,
          labelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
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
              _ResponsesTab(submissions: widget.hw.submissions),
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
        SnackBar(
          content: const Text('Eslatma yuborildi'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
              AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
          backgroundColor: const Color(0xFF0F9A6E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
              AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
          backgroundColor: AppColors.danger,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
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
              style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.m,
            children: [
              if (hw.groupName.isNotEmpty)
                _InfoBadge(icon: Icons.group_outlined, label: hw.groupName),
              if (hw.subject.isNotEmpty)
                _InfoBadge(icon: Icons.book_outlined, label: hw.subject),
              if (hw.deadline.isNotEmpty)
                _InfoBadge(
                  icon: Icons.schedule_outlined,
                  label: _formatDate(hw.deadline),
                  color: hw.isActive ? AppColors.brandMuted : AppColors.danger,
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

class _StatsHero extends StatelessWidget {
  final HomeworkStats? stats;

  const _StatsHero({this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.l, 0, AppSpacing.l, AppSpacing.l),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.brandSoft,
          borderRadius: BorderRadius.circular(AppRadii.m),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'Topshirdi',
              value: '${stats!.submitted}/${stats!.total}',
              color: AppColors.brand,
            ),
            _StatItem(
              label: 'O\'z vaqtida',
              value: '${stats!.onTime}',
              color: const Color(0xFF0F9A6E),
            ),
            _StatItem(
              label: 'Kechikdi',
              value: '${stats!.pending}',
              color: AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleL.copyWith(color: color),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.brandMuted),
        ),
      ],
    );
  }
}

class _ResponsesTab extends StatelessWidget {
  final List<HomeworkSubmission> submissions;

  const _ResponsesTab({required this.submissions});

  @override
  Widget build(BuildContext context) {
    if (submissions.isEmpty) {
      return const AlochiEmptyState(
        title: 'Javoblar yo\'q',
        subtitle: "Hali hech bir o'quvchi vazifani topshirmagan",
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.l),
      itemCount: submissions.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (context, index) {
        final sub = submissions[index];
        final hasSubmitted = sub.submittedAt.isNotEmpty;

        return AlochiCard(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              _Avatar(name: sub.studentName),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.studentName,
                      style:
                          AppTextStyles.titleM.copyWith(color: AppColors.ink),
                    ),
                    Text(
                      hasSubmitted
                          ? _formatDateTime(sub.submittedAt)
                          : 'Topshirilmagan',
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.brandMuted),
                    ),
                  ],
                ),
              ),
              if (hasSubmitted)
                AlochiPill(
                  label: sub.isOnTime ? 'O\'z vaqtida' : 'Kechikdi',
                  variant: sub.isOnTime
                      ? AlochiPillVariant.success
                      : AlochiPillVariant.danger,
                )
              else
                IconButton(
                  icon: const Icon(Icons.notifications_active_outlined,
                      color: AppColors.accent, size: 20),
                  onPressed: () {
                    // In a real app, this would call remind student endpoint
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${sub.studentName}ga eslatma yuborildi"),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF0F9A6E),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').take(2).map((e) => e[0]).join();
    return CircleAvatar(
      radius: 20,
      backgroundColor: _getAvatarColor(name),
      child: Text(
        initials.toUpperCase(),
        style: AppTextStyles.label.copyWith(color: Colors.white),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final hash = name.codeUnits.fold(0, (prev, e) => prev + e);
    final colors = [
      AppColors.brand,
      Colors.indigo,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
    ];
    return colors[hash % colors.length];
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
                        style:
                            AppTextStyles.titleM.copyWith(color: AppColors.ink),
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
              style: AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
