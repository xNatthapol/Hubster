import 'package:dio/dio.dart';
import 'package:hubster_app/core/api/api_client.dart';
import 'package:hubster_app/models/auth/auth_response.dart';
import 'package:hubster_app/models/auth/login_request.dart';
import 'package:hubster_app/models/auth/signup_request.dart';
import 'package:hubster_app/models/auth/user.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hubster_app/models/user/update_user_request.dart';

// Handles authentication-related API calls and token management.
@lazySingleton
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
    print("AuthService: Calling /auth/me");
    try {
      final response = await _apiClient.dio.get('/auth/me');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      print(
        "AuthService: getMe failed - Status: ${e.response?.statusCode}, Data: ${e.response?.data}",
      );
      throw Exception(
        e.response?.data['error'] ?? 'Failed to fetch user details',
      );
    }
  }

  // Updates the current user's profile.
  Future<User> updateUserProfile(UpdateUserRequest request) async {
    print("AuthService: Calling PATCH /users/me/profile");
    try {
      final response = await _apiClient.dio.patch(
        '/users/me/profile',
        data: request.toJson(),
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      print(
        "AuthService: updateUserProfile failed - Status: ${e.response?.statusCode}, Data: ${e.response?.data}",
      );
      throw Exception(e.response?.data['error'] ?? 'Failed to update profile');
    }
  }
}
