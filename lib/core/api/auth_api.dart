import 'api_client.dart';
import '../models/user.dart';
import '../storage/storage.dart';

class AuthApi {
  final _client = ApiClient.instance;

  Future<UserModel> login(String username, String password) async {
    final data = await _client.post('/auth/login/', data: {
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    await AppStorage.saveTokens(
        data['access'] as String, data['refresh'] as String);
    return me();
  }

  Future<UserModel> me() async {
    final data = await _client.get('/auth/me/') as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout/', data: {});
    } catch (_) {}
    await AppStorage.clearAll();
  }

  Future<void> forgotPassword(String username) async {
    await _client
        .post('/auth/forgot-password/', data: {'username': username});
  }
}
