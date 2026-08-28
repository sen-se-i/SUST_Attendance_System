class UserModel {
  final String id;
  final String email;
  final String role;
  final String? registrationNo;
  final String token;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.registrationNo,
    required this.token,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isTeacher => role.toUpperCase() == 'TEACHER';
  bool get isStudent => role.toUpperCase() == 'STUDENT';

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? json['registrationNo']?.toString() ?? '',
      role: json['role']?.toString() ?? 'STUDENT',
      registrationNo: json['registrationNo']?.toString(),
      token: token,
    );
  }
}
