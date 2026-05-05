import 'api_client.dart';
import '../models/user.dart';
import '../storage/storage.dart';

class AuthApi {
  final _client = ApiClient.instance;

  Future<UserModel> login(String username, String password) async {
    final data = await _client.post('/auth/login', data: {
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    final access = (data['access'] ?? data['access_token'])?.toString() ?? '';
    final refresh = data['refresh']?.toString() ?? access;
    if (access.isEmpty) throw Exception('Token olishda xatolik');
    await AppStorage.saveTokens(access, refresh);
    // Populate user from login response if /auth/me is not available
    final userJson = data['user'] as Map<String, dynamic>?;
    if (userJson != null) {
      return UserModel.fromJson(userJson);
    }
    return me();
  }

  Future<UserModel> me() async {
    final data = await _client.get('/auth/me') as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout', data: {});
    } catch (_) {}
    await AppStorage.clearAll();
  }

  Future<void> forgotPassword(String username) async {
    await _client
        .post('/auth/forgot-password/', data: {'username': username});
  }
}
