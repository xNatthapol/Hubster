import 'package:dio/dio.dart';
import 'package:hubster_app/core/api/api_client.dart';
import 'package:hubster_app/models/auth/auth_response.dart';
import 'package:hubster_app/models/auth/login_request.dart';
import 'package:hubster_app/models/auth/signup_request.dart';
import 'package:hubster_app/models/auth/user.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Handles authentication-related API calls and token management.
@lazySingleton // Registers this service with GetIt
class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  // Attempts to log in the user with provided credentials.
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: request.toJson(),
      );
      final authResponse = AuthResponse.fromJson(response.data);
      await _saveToken(authResponse.token);
      return authResponse;
    } on DioException catch (e) {
      // Handle specific Dio errors or rethrow a custom error
      print("Login error: ${e.response?.data ?? e.message}");
      throw Exception(e.response?.data['error'] ?? 'Login failed');
    }
  }

  // Attempts to sign up a new user.
  Future<User> signup(SignUpRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/signup',
        data: request.toJson(),
      );
      // Assuming signup returns the User object directly (excluding password)
      return User.fromJson(response.data);
    } on DioException catch (e) {
      print("Signup error: ${e.response?.data ?? e.message}");
      throw Exception(e.response?.data['error'] ?? 'Signup failed');
    }
  }

  // Saves the authentication token securely.
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Retrieves the authentication token.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Clears the authentication token (logout).
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Checks if a user is currently authenticated.
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<User> getMe() async {
    // No need to check token here, ApiClient interceptor adds it.
    // If token is missing/invalid, interceptor or backend will return 401.
    print("AuthService: Calling /auth/me"); // DEBUG
    try {
      final response = await _apiClient.dio.get(
        '/auth/me',
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      print(
        "AuthService: getMe failed - Status: ${e.response?.statusCode}, Data: ${e.response?.data}",
      ); // DEBUG
      // The ViewModel will handle this exception and can decide to logout if it's a 401
      throw Exception(
        e.response?.data['error'] ?? 'Failed to fetch user details',
      );
    }
  }
}
