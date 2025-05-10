import 'package:equatable/equatable.dart';

// Represents the user data structure.
class User extends Equatable {
  final int id;
  final String email;

  const User({required this.id, required this.email});

  // Factory constructor for creating a new User instance from a map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'] as int, email: json['email'] as String);
  }

  @override
  List<Object?> get props => [id, email];
}
