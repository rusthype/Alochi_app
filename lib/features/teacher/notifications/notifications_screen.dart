import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../shared/widgets/alochi_skeleton.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/models/notification.dart';
import '../../../core/services/fcm_service.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final fcmAvailable = FCMService().isAvailable;

    return Scaffold(
      appBar: AlochiAppBar(
        title: 'Bildirishnomalar',
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationActionProvider.notifier).markAllAsRead(),
            child: Text(
              'Hammasini o\'qildi',
              style: AppTextStyles.label.copyWith(color: AppColors.brand),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (kDebugMode && !fcmAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.danger.withValues(alpha: 0.1),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.danger),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'FCM (Push) sozlanmagan. google-services.json yo\'q.',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const AlochiEmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: "Hali bildirishnomalar yo'q",
                    subtitle: "Yangi xabarlar va eslatmalar bu yerda ko'rinadi",
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(notificationsProvider.future),
                  color: AppColors.brand,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.s),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _NotificationCard(notification: notification);
                    },
                  ),
                );
              },
              loading: () => const _NotificationsSkeleton(),
              error: (err, _) => AlochiEmptyState(
                icon: Icons.error_outline_rounded,
                iconColor: AppColors.danger,
                title: 'Yuklab bo\'lmadi',
                subtitle: err.toString(),
                actionLabel: "Qayta urinish",
                onAction: () => ref.refresh(notificationsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (notification.type) {
      case 'homework':
        icon = Icons.assignment_outlined;
        iconColor = AppColors.brand;
        bgColor = isDark
            ? AppColors.brand.withValues(alpha: 0.15)
            : const Color(0xFFE8F2EF);
        break;
      case 'message':
        icon = Icons.chat_bubble_outline_rounded;
        iconColor = AppColors.accent; // Coral
        bgColor = isDark
            ? AppColors.accent.withValues(alpha: 0.15)
            : const Color(0xFFFEF4EB);
        break;
      case 'attendance':
        icon = Icons.person_search_outlined;
        iconColor = AppColors.info; // Info
        bgColor = isDark
            ? AppColors.info.withValues(alpha: 0.15)
            : const Color(0xFFE0F2FE);
        break;
      case 'grade':
        icon = Icons.star_outline_rounded;
        iconColor = AppColors.success; // Success
        bgColor = isDark
            ? AppColors.success.withValues(alpha: 0.15)
            : const Color(0xFFECFDF5);
        break;
      case 'system':
        icon = Icons.settings_outlined;
        iconColor = AppColors.gray;
        bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
        break;
      case 'telegram':
        icon = Icons.send_rounded;
        iconColor = AppColors.brand;
        bgColor = isDark
            ? AppColors.brand.withValues(alpha: 0.15)
            : const Color(0xFFE8F2EF);
        break;
      default:
        icon = Icons.notifications_none_rounded;
        iconColor = AppColors.brand;
        bgColor = isDark
            ? AppColors.brand.withValues(alpha: 0.15)
            : const Color(0xFFE8F2EF);
    }

    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          ref
              .read(notificationActionProvider.notifier)
              .markAsRead(notification.id);
        }
        if (notification.actionUrl != null &&
            notification.actionUrl!.isNotEmpty) {
          context.push(notification.actionUrl!);
        }
      },
      child: AlochiCard(
        padding: const EdgeInsets.all(AppSpacing.l),
        backgroundColor: Theme.of(context).cardColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.titleM.copyWith(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.brand,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodyS.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeAgo(notification.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.l),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (_, __) => AlochiCard(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: AlochiSkeleton(height: 16)),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AlochiSkeleton(height: 14),
                  const SizedBox(height: 4),
                  AlochiSkeleton(width: 100, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
