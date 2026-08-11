class ClassModel {
  final String id;
  final String code;
  final String department;
  final String academicSession;
  final String subjectCode;

  ClassModel({
    required this.id,
    required this.code,
    required this.department,
    required this.academicSession,
    required this.subjectCode,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      department: json['department'] ?? '',
      academicSession: json['academicSession'] ?? '',
      subjectCode: json['subjectCode'] ?? '',
    );
  }
}
