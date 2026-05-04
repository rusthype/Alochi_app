import 'api_client.dart';
import '../models/teacher_dashboard.dart';

class TeacherApi {
  final _client = ApiClient.instance;

  Future<TeacherDashboardSummary> getDashboardSummary() async {
    final data = await _client.get('/teacher/dashboard/summary/') as Map<String, dynamic>;
    return TeacherDashboardSummary.fromJson(data);
  }
}
