import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../dashboard/dashboard_provider.dart';
import 'telegram_provider.dart';

class UnlinkedParentsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const UnlinkedParentsScreen({super.key, required this.groupId});

  @override
  ConsumerState<UnlinkedParentsScreen> createState() =>
      _UnlinkedParentsScreenState();
}

class _UnlinkedParentsScreenState extends ConsumerState<UnlinkedParentsScreen> {
  final Set<String> _sending = {};
  bool _sendingAll = false;

  @override
  Widget build(BuildContext context) {
    final parentsAsync = ref.watch(unlinkedParentsProvider(widget.groupId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.ink, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/teacher/profile/telegram');
            }
          },
        ),
        title: Text(
          "Ulanmagan ota-onalar",
          style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: parentsAsync.when(
        data: (parents) {
          if (parents.isEmpty) {
            return const _AllLinkedState();
          }
          return _ParentsList(
            parents: parents,
            sending: _sending,
            sendingAll: _sendingAll,
            onSendReminder: _sendReminder,
            onSendAll: () => _sendAllReminders(parents),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (err, _) {
          final isNotFound = err.toString().contains('topilmadi') ||
              err.toString().contains('404') ||
              err.toString().contains('Not found');
          if (isNotFound) {
            return const _ComingSoonState();
          }
          return AlochiEmptyState(
            title: "Yuklashda xato",
            subtitle: err.toString(),
            ctaLabel: "Qayta urinish",
            onCtaPressed: () =>
                ref.invalidate(unlinkedParentsProvider(widget.groupId)),
          );
        },
      ),
    );
  }

  Future<void> _sendReminder(String parentId) async {
    if (_sending.contains(parentId)) return;
    setState(() => _sending.add(parentId));
    try {
      final api = ref.read(teacherApiProvider);
      // POST endpoint will be added by backend agent
      // For now call the endpoint and handle gracefully
      await api.sendTelegramReminder(widget.groupId, parentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Eslatma yuborildi',
              style: AppTextStyles.bodyS.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Eslatma yuborilmadi: ${e.toString()}',
              style: AppTextStyles.bodyS.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending.remove(parentId));
    }
  }

  Future<void> _sendAllReminders(List<UnlinkedParentData> parents) async {
    if (_sendingAll) return;
    setState(() => _sendingAll = true);
    try {
      final api = ref.read(teacherApiProvider);
      await api.sendTelegramReminderAll(widget.groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Barcha ${parents.length} ota-onaga eslatma yuborildi",
              style: AppTextStyles.bodyS.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Eslatma yuborilmadi: ${e.toString()}',
              style: AppTextStyles.bodyS.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingAll = false);
    }
  }
}

// ─── Parents list ─────────────────────────────────────────────────────────────

class _ParentsList extends StatelessWidget {
  final List<UnlinkedParentData> parents;
  final Set<String> sending;
  final bool sendingAll;
  final void Function(String) onSendReminder;
  final VoidCallback onSendAll;

  const _ParentsList({
    required this.parents,
    required this.sending,
    required this.sendingAll,
    required this.onSendReminder,
    required this.onSendAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.l),
            itemCount: parents.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
            itemBuilder: (context, index) {
              final parent = parents[index];
              return _ParentRow(
                parent: parent,
                isSending: sending.contains(parent.parentId),
                onSend: () => onSendReminder(parent.parentId),
              );
            },
          ),
        ),
        // Bulk action bar
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.l,
            right: AppSpacing.l,
            top: AppSpacing.m,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.m,
          ),
          child: AlochiButton.telegram(
            label: "Hammasiga eslatma (${parents.length} kishi)",
            icon: Icons.send_rounded,
            isLoading: sendingAll,
            onPressed: sendingAll ? null : onSendAll,
          ),
        ),
      ],
    );
  }
}

class _ParentRow extends StatelessWidget {
  final UnlinkedParentData parent;
  final bool isSending;
  final VoidCallback onSend;

  const _ParentRow({
    required this.parent,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          AlochiAvatar(name: parent.parentName, size: 40),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parent.parentName.isEmpty ? 'Ota-ona' : parent.parentName,
                  style: AppTextStyles.titleM
                      .copyWith(color: AppColors.ink, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (parent.studentName.isNotEmpty)
                  Text(
                    "O'quvchi: ${parent.studentName}",
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.brandMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          SizedBox(
            width: 100,
            height: 36,
            child: ElevatedButton(
              onPressed: isSending ? null : onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0088CC),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.s),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.send_rounded, size: 14),
                        const SizedBox(width: 4),
                        Text('Eslatma',
                            style: AppTextStyles.label
                                .copyWith(color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── All linked state ─────────────────────────────────────────────────────────

class _AllLinkedState extends StatelessWidget {
  const _AllLinkedState();

  @override
  Widget build(BuildContext context) {
    return AlochiEmptyState(
      title: "Barchasi ulangan",
      subtitle: "Barcha ota-onalar Telegram botga ulangan",
      ctaLabel: '',
      onCtaPressed: null,
    );
  }
}

// ─── Coming-soon state ────────────────────────────────────────────────────────

class _ComingSoonState extends StatelessWidget {
  const _ComingSoonState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(AppRadii.xxl),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Color(0xFF0088CC),
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              "Ulanmagan ota-onalar",
              style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              "Bu funksiya tez orada qo'shiladi",
              style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
