class UserModel {
  final String id;
  final String email;
  final String role; // 'ADMIN' (Teacher) or 'STUDENT'
  final String? registrationNo;
  final String token;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.registrationNo,
    required this.token,
  });

  bool get isTeacher => role.toUpperCase() == 'ADMIN' || role.toUpperCase() == 'TEACHER';

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'STUDENT',
      registrationNo: json['registrationNo'],
      token: token,
    );
  }
}
