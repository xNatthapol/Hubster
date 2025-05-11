// Data structure for signup request payload.
class SignUpRequest {
  final String email;
  final String password;
  final String fullName;

  SignUpRequest({
    required this.email,
    required this.password,
    required this.fullName,
  });

  // Converts SignUpRequest instance to a JSON map for API call.
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password, 'full_name': fullName};
  }
}
