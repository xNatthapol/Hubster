// Data structure for login request payload.
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  // Converts LoginRequest instance to a JSON map for API call.
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}
