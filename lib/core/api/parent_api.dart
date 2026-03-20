import 'api_client.dart';
import '../models/notification.dart';

class ParentApi {
  final _client = ApiClient.instance;

  Future<List<Map<String, dynamic>>> getChildren() async {
    final data = await _client.get('/parent/');
    final list = (data is Map
            ? data['children'] ?? data['results'] ?? data
            : data) as List? ??
        [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getChildDetail(String id) async =>
      await _client.get('/parent/children/$id/') as Map<String, dynamic>;

  Future<List<AppNotification>> getNotifications() async {
    final data = await _client.get('/notifications/');
    final list = (data is Map ? data['results'] ?? data : data) as List? ?? [];
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAllRead() async =>
      await _client.post('/notifications/mark-all-read/', data: {});
}
