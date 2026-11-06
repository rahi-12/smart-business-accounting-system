class UserProfile {
  const UserProfile({
    required this.id,
    required this.firebaseUid,
    required this.fullName,
    required this.username,
    required this.email,
  });

  final String id;
  final String firebaseUid;
  final String fullName;
  final String username;
  final String email;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? '').toString(),
      firebaseUid: (json['firebase_uid'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}
