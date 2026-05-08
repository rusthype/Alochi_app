import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_avatar.dart';
import '../../../shared/widgets/alochi_button.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../shared/widgets/alochi_search_bar.dart';
import '../dashboard/dashboard_provider.dart';
import 'telegram_provider.dart';

enum ParentFilter { all, unlinked, sent }

class UnlinkedParentsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const UnlinkedParentsScreen({super.key, required this.groupId});

  @override
  ConsumerState<UnlinkedParentsScreen> createState() =>
      _UnlinkedParentsScreenState();
}

class _UnlinkedParentsScreenState extends ConsumerState<UnlinkedParentsScreen> {
  final Set<String> _sending = {};
  final Set<String> _locallySentIds = {};
  bool _sendingAll = false;
  String _searchQuery = '';
  ParentFilter _selectedFilter = ParentFilter.all;

  @override
  Widget build(BuildContext context) {
    final parentsAsync = ref.watch(unlinkedParentsProvider(widget.groupId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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

          final filteredParents = parents.where((p) {
            final matchesSearch = p.parentName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                p.studentName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());
            if (!matchesSearch) return false;

            final isSent =
                p.sentAt != null || _locallySentIds.contains(p.parentId);
            if (_selectedFilter == ParentFilter.unlinked) return !isSent;
            if (_selectedFilter == ParentFilter.sent) return isSent;
            return true;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l, AppSpacing.l, AppSpacing.l, 0),
                child: AlochiSearchBar(
                  hintText: "O'quvchi yoki ota-ona ismi",
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: Row(
                  children: [
                    _FilterChip(
                      label: "Hammasi",
                      isSelected: _selectedFilter == ParentFilter.all,
                      onTap: () =>
                          setState(() => _selectedFilter = ParentFilter.all),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    _FilterChip(
                      label: "Bog'lanmagan",
                      isSelected: _selectedFilter == ParentFilter.unlinked,
                      onTap: () => setState(
                          () => _selectedFilter = ParentFilter.unlinked),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    _FilterChip(
                      label: "Eslatma yuborilgan",
                      isSelected: _selectedFilter == ParentFilter.sent,
                      onTap: () =>
                          setState(() => _selectedFilter = ParentFilter.sent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Expanded(
                child: filteredParents.isEmpty
                    ? _NoResultsState(
                        isSearch: _searchQuery.isNotEmpty,
                      )
                    : _ParentsList(
                        parents: filteredParents,
                        sending: _sending,
                        locallySentIds: _locallySentIds,
                        sendingAll: _sendingAll,
                        onSendReminder: (p) =>
                            _sendReminder(p.parentId, p.parentName),
                        onSendAll: () => _sendAllReminders(parents),
                      ),
              ),
              if (parents.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  padding: EdgeInsets.only(
                    left: AppSpacing.l,
                    right: AppSpacing.l,
                    top: AppSpacing.m,
                    bottom:
                        MediaQuery.of(context).padding.bottom + AppSpacing.m,
                  ),
                  child: AlochiButton.telegram(
                    label: "Hammasiga eslatma (${parents.length} kishi)",
                    icon: Icons.send_rounded,
                    isLoading: _sendingAll,
                    onPressed:
                        _sendingAll ? null : () => _sendAllReminders(parents),
                  ),
                ),
            ],
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

  Future<void> _sendReminder(String parentId, String parentName) async {
    if (_sending.contains(parentId)) return;
    setState(() => _sending.add(parentId));
    try {
      final api = ref.read(teacherApiProvider);
      await api.sendTelegramReminder(widget.groupId, parentId);
      if (mounted) {
        setState(() => _locallySentIds.add(parentId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Eslatma yuborildi — ${parentName.isEmpty ? "Ota-ona" : parentName}',
              style: AppTextStyles.bodyS.copyWith(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
            ),
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
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
            backgroundColor: AppColors.danger,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
            ),
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
        setState(() {
          for (final p in parents) {
            _locallySentIds.add(p.parentId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Barcha ${parents.length} ota-onaga eslatma yuborildi",
              style: AppTextStyles.bodyS.copyWith(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
            ),
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
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
            backgroundColor: AppColors.danger,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.m),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingAll = false);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m, vertical: AppSpacing.s),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.round),
          border: Border.all(
              color: isSelected ? AppColors.brand : const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyS.copyWith(
            color: isSelected ? Colors.white : AppColors.brandMuted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Parents list ─────────────────────────────────────────────────────────────

class _ParentsList extends StatelessWidget {
  final List<UnlinkedParentData> parents;
  final Set<String> sending;
  final Set<String> locallySentIds;
  final bool sendingAll;
  final void Function(UnlinkedParentData) onSendReminder;
  final VoidCallback onSendAll;

  const _ParentsList({
    required this.parents,
    required this.sending,
    required this.locallySentIds,
    required this.sendingAll,
    required this.onSendReminder,
    required this.onSendAll,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.l),
      itemCount: parents.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (context, index) {
        final parent = parents[index];
        final isSent =
            parent.sentAt != null || locallySentIds.contains(parent.parentId);
        return _ParentRow(
          parent: parent,
          isSending: sending.contains(parent.parentId),
          isSent: isSent,
          onSend: () => onSendReminder(parent),
        );
      },
    );
  }
}

class _ParentRow extends StatelessWidget {
  final UnlinkedParentData parent;
  final bool isSending;
  final bool isSent;
  final VoidCallback onSend;

  const _ParentRow({
    required this.parent,
    required this.isSending,
    required this.isSent,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final lastSent = parent.sentAt;
    final timeStr = lastSent != null
        ? DateFormat('dd.MM HH:mm').format(lastSent.toLocal())
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadii.l),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlochiAvatar(name: parent.parentName, size: 40),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        parent.parentName.isEmpty
                            ? 'Ota-ona'
                            : parent.parentName,
                        style: AppTextStyles.titleM
                            .copyWith(color: AppColors.ink, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    _StatusBadge(isSent: isSent),
                  ],
                ),
                if (parent.studentName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "O'quvchi: ${parent.studentName}",
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.brandMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (parent.phone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      parent.phone,
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.brandMuted, fontSize: 12),
                    ),
                  ),
                if (timeStr != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "So'nggi urinish: $timeStr",
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          SizedBox(
            width: 90,
            height: 36,
            child: ElevatedButton(
              onPressed: isSending ? null : onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSent ? Colors.white : AppColors.brand,
                foregroundColor: isSent ? AppColors.brand : Colors.white,
                elevation: 0,
                side: isSent ? const BorderSide(color: AppColors.brand) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.s),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: AppColors.brand, strokeWidth: 2),
                    )
                  : Text(
                      isSent ? 'Yana bir bor' : 'Eslatma',
                      style: AppTextStyles.label.copyWith(
                        color: isSent ? AppColors.brand : Colors.white,
                        fontSize: 11,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isSent;

  const _StatusBadge({required this.isSent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSent
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.brand.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isSent ? "Eslatildi" : "Yangi",
        style: TextStyle(
          color: isSent ? AppColors.warning : AppColors.brand,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── States ──────────────────────────────────────────────────────────────────

class _NoResultsState extends StatelessWidget {
  final bool isSearch;

  const _NoResultsState({required this.isSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearch
                  ? Icons.search_off_rounded
                  : Icons.filter_list_off_rounded,
              size: 48,
              color: AppColors.brandMuted,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              isSearch ? "Natija topilmadi" : "Bu filtr bo'yicha ma'lumot yo'q",
              style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AllLinkedState extends StatelessWidget {
  const _AllLinkedState();

  @override
  Widget build(BuildContext context) {
    return const AlochiEmptyState(
      title: "Barchasi ulangan",
      subtitle: "Barcha ota-onalar Telegram botga ulangan",
      ctaLabel: '',
      onCtaPressed: null,
    );
  }
}

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
