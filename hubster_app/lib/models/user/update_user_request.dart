// Data structure for the profile update request payload.
// Fields are nullable because it's a PATCH request; only send what's changed.
class UpdateUserRequest {
  final String? fullName;
  final String? profilePictureUrl;
  final String? phoneNumber;

  UpdateUserRequest({this.fullName, this.profilePictureUrl, this.phoneNumber});

  // Converts UpdateUserRequest instance to a JSON map for API call.
  // Only include non-null fields in the JSON.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (fullName != null) {
      data['full_name'] = fullName;
    }
    if (profilePictureUrl != null) {
      // Handle empty string to signify clearing the picture if desired by backend
      data['profile_picture_url'] =
          profilePictureUrl == "" ? null : profilePictureUrl;
    }
    if (phoneNumber != null) {
      // Handle empty string to signify clearing phone if desired
      data['phone_number'] = phoneNumber == "" ? null : phoneNumber;
    }
    return data;
  }
}
