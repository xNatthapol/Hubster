// Data structure for signup request payload.
class SignUpRequest {
  final String email;
  final String password;

  SignUpRequest({required this.email, required this.password});

  // Converts SignUpRequest instance to a JSON map for API call.
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}
