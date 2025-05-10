import 'package:dio/dio.dart';
import 'package:hubster_app/core/config/app_config.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Handles HTTP requests using Dio, including base URL and interceptors.
@lazySingleton
class ApiClient {
  late Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to headers if available
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Handle API errors globally if needed
          print('API Error: ${e.response?.statusCode} - ${e.message}');
          if (e.response?.statusCode == 401) {
            // Potentially trigger logout or token refresh
            print('Unauthorized access - token might be invalid or expired.');
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
