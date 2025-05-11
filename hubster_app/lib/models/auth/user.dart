import 'package:equatable/equatable.dart';

// Represents the user data structure received from the backend.
class User extends Equatable {
  final int id;
  final String email;
  final String fullName;
  final String? profilePictureUrl;
  final String? phoneNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.profilePictureUrl,
    this.phoneNumber,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor for creating a new User instance from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      profilePictureUrl: json['profile_picture_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])
              : null,
    );
  }

  // For Equatable
  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    profilePictureUrl,
    phoneNumber,
    createdAt,
    updatedAt,
  ];
}
