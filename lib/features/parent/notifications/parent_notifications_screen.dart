import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/api/parent_api.dart';
import '../../../core/models/notification.dart';

final _parentNotificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  return ParentApi().getNotifications();
});

class ParentNotificationsScreen extends ConsumerWidget {
  const ParentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_parentNotificationsProvider);
    return Scaffold(
      backgroundColor: kBgMain,
      appBar: AppBar(
        title: const Text('Bildirishnomalar'),
        actions: [
          TextButton(
            onPressed: () async {
              await ParentApi().markAllRead();
              ref.invalidate(_parentNotificationsProvider);
            },
            child: const Text("Barchasini o'qildi",
                style: TextStyle(color: kOrange, fontSize: 12)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(
            child: Text('Xatolik: $e',
                style: const TextStyle(color: kRed))),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(
                message: "Yangi bildirishnomalar yo'q",
                icon: Icons.notifications_none_rounded);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (ctx, i) =>
                _NotificationCard(n: notifications[i]),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification n;
  const _NotificationCard({required this.n});

  IconData _icon() {
    switch (n.type) {
      case 'test_completed':
        return Icons.check_circle_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'xp':
        return Icons.bolt_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'homework':
        return Icons.assignment_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _color() {
    switch (n.type) {
      case 'test_completed':
        return kGreen;
      case 'achievement':
        return kOrange;
      case 'xp':
        return kOrange;
      case 'streak':
        return kOrange;
      case 'homework':
        return kBlue;
      default:
        return kTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: n.isRead ? kBgCard : kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: n.isRead ? kBgBorder : color.withOpacity(0.3),
          width: n.isRead ? 1 : 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
                child: Icon(_icon(), color: color, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title,
                    style: TextStyle(
                        color: n.isRead
                            ? kTextSecondary
                            : kTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(n.body,
                    style: const TextStyle(
                        color: kTextMuted, fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (!n.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4, left: 8),
              decoration: const BoxDecoration(
                  color: kOrange, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
