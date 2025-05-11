import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/core/di/service_locator.dart';
import 'package:hubster_app/models/auth/login_request.dart';
import 'package:hubster_app/models/auth/signup_request.dart';
import 'package:hubster_app/services/auth_service.dart';
import 'auth_state.dart';
import 'package:hubster_app/models/user/update_user_request.dart';

// The StateNotifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthStateNotifier(this._authService) : super(const AuthState()) {
    // Initial state
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearOperationMessage: true,
    );
    print("AuthStateNotifier: _checkAuthStatus called");
    final hasToken = await _authService.isAuthenticated();
    if (hasToken) {
      try {
        final userFromApi = await _authService.getMe();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          currentUser: userFromApi,
          clearOperationMessage: true,
        );
        print(
          "AuthStateNotifier: _checkAuthStatus - User loaded: ${state.currentUser?.email}",
        );
      } catch (e) {
        print(
          "AuthStateNotifier: _checkAuthStatus - Error fetching user: $e. Logging out.",
        );
        await _authService.logout();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          operationMessage: "Session invalid. Please login again.",
          clearCurrentUser: true,
        );
      }
    } else {
      print("AuthStateNotifier: No token found. Setting unauthenticated.");
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearOperationMessage: true,
        clearCurrentUser: true,
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearOperationMessage: true,
    );
    print("AuthStateNotifier: login called.");
    try {
      final authResponse = await _authService.login(
        LoginRequest(email: email, password: password),
      );
      // Update state immutably
      state = state.copyWith(
        status: AuthStatus.authenticated,
        currentUser: authResponse.user,
        clearOperationMessage: true,
      );
      print(
        "AuthStateNotifier: login API success. User: ${state.currentUser?.email}",
      );
    } catch (e) {
      print("AuthStateNotifier: login API error: $e");
      state = state.copyWith(
        status: AuthStatus.error,
        operationMessage: e.toString(),
      );
    }
  }

  Future<void> signup(String email, String password, String fullName) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearOperationMessage: true,
    );
    try {
      await _authService.signup(
        SignUpRequest(email: email, password: password, fullName: fullName),
      );
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        operationMessage: "Signup successful! Please login.",
        clearCurrentUser: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        operationMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    // Keep current user during loading phase of logout for potential UI display
    state = state.copyWith(
      status: AuthStatus.loading,
      clearOperationMessage: true,
    );
    print("AuthStateNotifier: logout initiated.");
    await _authService.logout();
    // Use Timer.run to ensure state update happens in a new event loop tick
    Timer.run(() {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearCurrentUser: true,
        clearOperationMessage: true,
      );
      print(
        "AuthStateNotifier: logout - state set to unauthenticated via Timer.run.",
      );
    });
  }

  Future<bool> updateUserProfile(UpdateUserRequest request) async {
    if (state.status != AuthStatus.authenticated || state.currentUser == null) {
      print(
        "AuthStateNotifier: Cannot update profile, user not authenticated.",
      );
      state = state.copyWith(
        status: AuthStatus.error,
        operationMessage: "User not authenticated.",
      );
      return false;
    }

    final previousStatus = state.status;
    state = state.copyWith(
      status: AuthStatus.loading,
      clearOperationMessage: true,
    );
    print("AuthStateNotifier: updateUserProfile called.");

    try {
      final updatedUser = await _authService.updateUserProfile(request);
      // Update the currentUser in the state with the fresh data from the backend.
      state = state.copyWith(
        status: AuthStatus.authenticated,
        currentUser: updatedUser,
        operationMessage: "Profile updated successfully!",
      );
      print(
        "AuthStateNotifier: Profile update success. User: ${state.currentUser?.email}",
      );
      return true;
    } catch (e) {
      print("AuthStateNotifier: Profile update error: $e");
      state = state.copyWith(
        status: previousStatus,
        operationMessage: e.toString(),
      );
      return false;
    }
  }

  void clearOperationMessage() {
    if (state.operationMessage != null) {
      state = state.copyWith(clearOperationMessage: true);
      print("AuthStateNotifier: Cleared operationMessage.");
    }
  }
}

// Define the global Riverpod provider for AuthStateNotifier
final authStateNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
      // Get AuthService instance from GetIt
      final authService = getIt<AuthService>();
      return AuthStateNotifier(authService);
    });
