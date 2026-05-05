import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../../shared/widgets/alochi_empty_state.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/models/notification.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AlochiAppBar(
        title: 'Bildirishnomalar',
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationActionProvider.notifier).markAllAsRead(),
            child: Text(
              'Hammasini o\'qildi',
              style: AppTextStyles.label.copyWith(color: AppColors.brand),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
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
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
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
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (notification.type) {
      case 'homework':
        icon = Icons.assignment_outlined;
        iconColor = AppColors.brand;
        bgColor = const Color(0xFFE8F2EF);
        break;
      case 'message':
        icon = Icons.chat_bubble_outline_rounded;
        iconColor = const Color(0xFFE8954E); // Coral
        bgColor = const Color(0xFFFEF4EB);
        break;
      case 'attendance':
        icon = Icons.person_search_outlined;
        iconColor = const Color(0xFF0EA5E9); // Info
        bgColor = const Color(0xFFE0F2FE);
        break;
      case 'grade':
        icon = Icons.star_outline_rounded;
        iconColor = const Color(0xFF0F9A6E); // Success
        bgColor = const Color(0xFFECFDF5);
        break;
      case 'system':
        icon = Icons.settings_outlined;
        iconColor = const Color(0xFF6B7280);
        bgColor = const Color(0xFFF3F4F6);
        break;
      case 'telegram':
        icon = Icons.send_rounded;
        iconColor = AppColors.brand;
        bgColor = const Color(0xFFE8F2EF);
        break;
      default:
        icon = Icons.notifications_none_rounded;
        iconColor = AppColors.brand;
        bgColor = const Color(0xFFE8F2EF);
    }

    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          ref.read(notificationActionProvider.notifier).markAsRead(notification.id);
        }
        if (notification.actionUrl != null && notification.actionUrl!.isNotEmpty) {
          context.push(notification.actionUrl!);
        }
      },
      child: AlochiCard(
        padding: const EdgeInsets.all(AppSpacing.l),
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
                            color: AppColors.ink,
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
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
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodyS.copyWith(
                      color: notification.isRead ? AppColors.brandMuted : AppColors.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeAgo(notification.createdAt),
                    style: AppTextStyles.caption.copyWith(color: AppColors.brandMuted),
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
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 120, color: const Color(0xFFF3F4F6)),
                  const SizedBox(height: 8),
                  Container(height: 14, width: double.infinity, color: const Color(0xFFF3F4F6)),
                  const SizedBox(height: 4),
                  Container(height: 14, width: 200, color: const Color(0xFFF3F4F6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
