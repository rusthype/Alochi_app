import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../shared/widgets/alochi_skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'telegram_broadcast_screen.dart';
import 'telegram_provider.dart';
import 'telegram_tutorial_overlay.dart';

class TelegramParentsScreen extends ConsumerStatefulWidget {
  const TelegramParentsScreen({super.key});

  @override
  ConsumerState<TelegramParentsScreen> createState() =>
      _TelegramParentsScreenState();
}

class _TelegramParentsScreenState extends ConsumerState<TelegramParentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });
  }

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('telegram_tutorial_seen') ?? false;
    if (!seen && mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const TelegramTutorialOverlay(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(telegramGroupsProvider);

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
              context.go('/teacher/profile');
            }
          },
        ),
        title: Text(
          "Telegram ota-onalar",
          style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const AlochiEmptyState(
              icon: Icons.send_rounded,
              title: "Ota-onalar bog'lanmagan",
              subtitle: "Telegram orqali bog'lanish uchun guruhda kod ulashing",
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(telegramGroupsProvider);
              await ref.read(telegramGroupsProvider.future);
            },
            color: AppColors.brand,
            child: _GroupsList(groups: groups),
          );
        },
        loading: () => const _TelegramLoadingSkeleton(),
        error: (err, _) {
          return AlochiEmptyState(
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.danger,
            title: "Ma'lumotlarni yuklashda xato",
            subtitle: err.toString(),
            actionLabel: "Qayta urinish",
            onAction: () => ref.invalidate(telegramGroupsProvider),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/teacher/telegram/broadcast'),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.send_rounded),
        label: const Text("Broadcast"),
        elevation: 2,
      ),
    );
  }
}

class _TelegramLoadingSkeleton extends StatelessWidget {
  const _TelegramLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: const [
        AlochiSkeleton(height: 60),
        SizedBox(height: AppSpacing.l),
        AlochiSkeletonCard(height: 120),
        SizedBox(height: AppSpacing.m),
        AlochiSkeletonCard(height: 120),
        SizedBox(height: AppSpacing.m),
        AlochiSkeletonCard(height: 120),
      ],
    );
  }
}

// ─── Explainer banner ─────────────────────────────────────────────────────────

class _ExplainerBanner extends StatelessWidget {
  const _ExplainerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(AppRadii.m),
        border: Border.all(color: const Color(0xFFBFD4FB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF0088CC), size: 18),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              "Ota-onalar Telegram botiga o'zlari ulanadi. Sizning Telegram akkauntingiz kerak emas.",
              style: AppTextStyles.bodyS.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Groups list ─────────────────────────────────────────────────────────────

class _GroupsList extends ConsumerWidget {
  final List<TelegramGroupStatusData> groups;

  const _GroupsList({required this.groups});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        _TelegramSummaryCard(
          totalGroups: groups.length,
          totalParents: groups.fold(0, (s, g) => s + g.totalParents),
          linkedParents: groups.fold(0, (s, g) => s + g.linkedCount),
        ),
        const SizedBox(height: AppSpacing.l),
        const _ExplainerBanner(),
        const SizedBox(height: AppSpacing.l),
        ...groups.map((group) => _GroupCard(
              group: group,
              onTap: () => context
                  .push('/teacher/telegram/groups/${group.groupId}/unlinked'),
            )),
      ],
    );
  }
}

class _TelegramSummaryCard extends StatelessWidget {
  final int totalGroups;
  final int totalParents;
  final int linkedParents;

  const _TelegramSummaryCard({
    required this.totalGroups,
    required this.totalParents,
    required this.linkedParents,
  });

  @override
  Widget build(BuildContext context) {
    final percent = totalParents > 0 ? linkedParents / totalParents : 0.0;
    final statusColor = percent >= 0.75
        ? AppColors.success
        : percent >= 0.5
            ? AppColors.warning
            : AppColors.danger;

    return AlochiCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatTile(
                label: "Guruhlar",
                value: totalGroups.toString(),
              ),
              _StatTile(
                label: "Ota-onalar",
                value: totalParents.toString(),
              ),
              _StatTile(
                label: "Ulangan",
                value: "${(percent * 100).round()}%",
                valueColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.round),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleL.copyWith(
            color: valueColor ?? AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodyS.copyWith(color: AppColors.gray),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final TelegramGroupStatusData group;
  final VoidCallback onTap;

  const _GroupCard({required this.group, required this.onTap});

  void _showQrDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _QrBottomSheet(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent = group.linkedPercent;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: GestureDetector(
        onTap: onTap,
        child: AlochiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.groupName,
                          style: AppTextStyles.titleM
                              .copyWith(color: AppColors.ink),
                        ),
                        if (group.subject.isNotEmpty)
                          Text(
                            group.subject,
                            style: AppTextStyles.bodyS
                                .copyWith(color: AppColors.brandMuted),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Color(0xFF0088CC), size: 20),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TelegramBroadcastScreen(),
                        ),
                      );
                    },
                    tooltip: "Xabar yuborish",
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_rounded,
                        color: AppColors.brand),
                    onPressed: () => _showQrDialog(context),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.brandMuted),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  Text(
                    '${group.linkedCount}/${group.totalParents} ota-ona ulangan',
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.brandMuted),
                  ),
                  const Spacer(),
                  Text(
                    '${(percent * 100).round()}%',
                    style: AppTextStyles.label.copyWith(
                      color: percent >= 0.75
                          ? AppColors.success
                          : percent >= 0.5
                              ? AppColors.warning
                              : AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.round),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percent >= 0.75
                        ? AppColors.success
                        : percent >= 0.5
                            ? AppColors.warning
                            : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Top-level function for Telegram chooser
Future<void> _openTelegramWithChoice(
    BuildContext context, String deepLink, String groupName) async {
  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _TelegramAccountChooser(
      deepLink: deepLink,
      groupName: groupName,
    ),
  );
}

class _QrBottomSheet extends StatelessWidget {
  final TelegramGroupStatusData group;

  const _QrBottomSheet({required this.group});

  String get _deepLink =>
      'https://t.me/alochi_uz_bot?start=group_${group.groupId}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.groupName,
                  style: AppTextStyles.titleL.copyWith(color: AppColors.ink),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadii.l),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: _deepLink,
              version: QrVersions.auto,
              size: 240.0,
              gapless: false,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.ink,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            _deepLink,
            style: AppTextStyles.bodyS.copyWith(color: AppColors.brand),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.copy_rounded,
                label: "Nusxa olish",
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _deepLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Havola nusxalandi")),
                  );
                },
              ),
              _ActionButton(
                icon: Icons.share_rounded,
                label: "Ulashish",
                onTap: () {
                  Share.share(
                    'A\'lochi botga ulaning: $_deepLink',
                  );
                },
              ),
              _ActionButton(
                icon: Icons.telegram_rounded,
                label: "Telegram",
                onTap: () => _openTelegramWithChoice(
                    context, _deepLink, group.groupName),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            "QR kod 24 soat amal qiladi",
            style: AppTextStyles.bodyS.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: AppSpacing.m),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.m),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Icon(icon, color: AppColors.brand, size: 24),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(label,
                style: AppTextStyles.label.copyWith(color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

// ─── Telegram account chooser ─────────────────────────────────────────────────

class _TelegramAccountChooser extends StatefulWidget {
  final String deepLink;
  final String groupName;

  const _TelegramAccountChooser({
    required this.deepLink,
    required this.groupName,
  });

  @override
  State<_TelegramAccountChooser> createState() =>
      _TelegramAccountChooserState();
}

class _TelegramAccountChooserState extends State<_TelegramAccountChooser> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        top: AppSpacing.l,
        left: AppSpacing.l,
        right: AppSpacing.l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          Text(
            'Qaysi Telegram bilan ochish?',
            style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            widget.groupName,
            style: AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
          ),
          const SizedBox(height: AppSpacing.l),

          // Option 1: system default (shows Android chooser)
          _ChoiceRow(
            icon: Icons.open_in_new_rounded,
            label: 'Standart Telegram',
            subtitle: "Telefonimdagi asosiy Telegram",
            onTap: () => _launch(LaunchMode.externalApplication),
          ),

          const Divider(height: AppSpacing.l),

          // Option 2: system chooser (shows all Telegram apps)
          _ChoiceRow(
            icon: Icons.apps_rounded,
            label: "Ilovani tanlash",
            subtitle: "Telegram, Telegram X, parallel akkaunt...",
            onTap: () => _launch(LaunchMode.platformDefault),
          ),

          const Divider(height: AppSpacing.l),

          // Option 3: copy link (user pastes manually)
          _ChoiceRow(
            icon: Icons.copy_rounded,
            label: "Havolani nusxalash",
            subtitle: "O'zim tanlagan Telegramga joylashaman",
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.deepLink));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      "Havola nusxalandi — Telegramga yopishtirib yuboring"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.m),
        ],
      ),
    );
  }

  Future<void> _launch(LaunchMode mode) async {
    Navigator.pop(context);
    final uri = Uri.parse(widget.deepLink);
    try {
      await launchUrl(uri, mode: mode);
    } catch (_) {
      // Fallback: share sheet
      Share.share('A\'lochi botga ulaning: ${widget.deepLink}');
    }
  }
}

class _ChoiceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.m),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FB),
                borderRadius: BorderRadius.circular(AppRadii.s),
              ),
              child: Icon(icon, color: const Color(0xFF0088CC), size: 22),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.brandMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.brandMuted),
          ],
        ),
      ),
    );
  }
}
