import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../storage/storage.dart';

/// Base URL: only the host, WITHOUT /api/v1 suffix.
/// The /api/v1 prefix is appended below in BaseOptions.
/// dart-define should be: --dart-define=API_URL=https://api.alochi.org
const _baseHost = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://api.alochi.org',
);

// Strip any trailing /api/v1 if accidentally included in dart-define
final _baseUrl = _baseHost.endsWith('/api/v1')
    ? _baseHost.substring(0, _baseHost.length - 7)
    : _baseHost.endsWith('/api/v1/')
        ? _baseHost.substring(0, _baseHost.length - 8)
        : _baseHost;

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
            final options = error.requestOptions;
            options.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await dio.fetch(options);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }

        final message = _getErrorMessage(error);
        _logger.e('API Error [${error.requestOptions.path}]: $message');
        handler.next(error);
      },
    ));
  }

  String _getErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Ulanish vaqti tugadi. Internet aloqasini tekshiring.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'Internet aloqasi yo\'q.';
    } else {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      switch (status) {
        case 400:
          return (data is Map && data.containsKey('detail'))
              ? data['detail'].toString()
              : 'Noto\'g\'ri so\'rov.';
        case 401:
          return 'Kirish huquqi yo\'q. Qayta kiring.';
        case 403:
          return 'Ruxsat yo\'q.';
        case 404:
          return 'Ma\'lumot topilmadi.';
        case 429:
          return 'Juda ko\'p so\'rov. Biroz kuting.';
        case 500:
          return 'Server xatosi. Keyinroq urinib ko\'ring.';
        default:
          return 'Xato yuz berdi.';
      }
    }
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

      final newRefresh = response.data['refresh'] as String? ?? oldRefresh;
      await AppStorage.saveTokens(newAccess, newRefresh);
      return true;
    } catch (_) {
      await AppStorage.clearAll();
      return false;
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await dio.get(path, queryParameters: params);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }
}
