import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../storage/storage.dart';

const _baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://alochi.org',
);

final _logger = Logger();

class ApiClient {
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();

  late final Dio dio;

  ApiClient._() {
    dio = Dio(BaseOptions(
      baseUrl: '$_baseUrl/api/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AppStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final token = await AppStorage.getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        _logger.e('API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final oldRefresh = await AppStorage.getRefreshToken();
      if (oldRefresh == null) return false;
      final response = await Dio().post(
        '$_baseUrl/api/v1/auth/token/refresh/',
        data: {'refresh': oldRefresh},
      );
      final newAccess = response.data['access'] as String?;
      if (newAccess == null) return false;
      final newRefresh =
          response.data['refresh'] as String? ?? oldRefresh;
      await AppStorage.saveTokens(newAccess, newRefresh);
      return true;
    } catch (_) {
      await AppStorage.clearAll();
      return false;
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    final response = await dio.get(path, queryParameters: params);
    return response.data;
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    final response = await dio.post(path, data: data);
    return response.data;
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    final response = await dio.patch(path, data: data);
    return response.data;
  }
}
