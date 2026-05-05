import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/teacher_api.dart';
import '../../../core/models/notification.dart';
import '../dashboard/dashboard_provider.dart';

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final api = ref.read(teacherApiProvider);
  return api.getNotifications();
});

class NotificationNotifier extends StateNotifier<void> {
  final Ref _ref;
  NotificationNotifier(this._ref) : super(null);

  Future<void> markAsRead(String id) async {
    try {
      final api = _ref.read(teacherApiProvider);
      await api.markNotificationAsRead(id);
      _ref.invalidate(notificationsProvider);
    } catch (_) {
      // Handle error if needed
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final api = _ref.read(teacherApiProvider);
      await api.markAllNotificationsAsRead();
      _ref.invalidate(notificationsProvider);
    } catch (_) {
      // Handle error if needed
    }
  }
}

final notificationActionProvider =
    StateNotifierProvider<NotificationNotifier, void>((ref) => NotificationNotifier(ref));

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final asyncNotifications = ref.watch(notificationsProvider);
  return asyncNotifications.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
