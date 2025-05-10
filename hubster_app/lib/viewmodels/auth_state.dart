import 'package:equatable/equatable.dart';
import 'package:hubster_app/models/auth/user.dart';

// Re-define AuthStatus enum here or import if it's in a shared location
enum AuthStatus { unknown, authenticated, unauthenticated, loading, error }

// Immutable state class for authentication
class AuthState extends Equatable {
  final AuthStatus status;
  final User? currentUser;
  final String? operationMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.currentUser,
    this.operationMessage,
  });

  // Helper method to create a new state by copying the old one
  AuthState copyWith({
    AuthStatus? status,
    User? currentUser,
    String? operationMessage,
    bool clearCurrentUser = false, // To explicitly set currentUser to null
    bool clearOperationMessage =
        false, // To explicitly set operationMessage to null
  }) {
    return AuthState(
      status: status ?? this.status,
      currentUser: clearCurrentUser ? null : (currentUser ?? this.currentUser),
      operationMessage:
          clearOperationMessage
              ? null
              : (operationMessage ?? this.operationMessage),
    );
  }

  @override
  List<Object?> get props => [status, currentUser, operationMessage];
}
