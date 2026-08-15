class ClassModel {
  final String id;
  final String code;
  final String department;
  final String academicSession;
  final String? semester;
  final String subjectCode;
  final String? subjectName;
  final double? credits;

  ClassModel({
    required this.id,
    required this.code,
    required this.department,
    required this.academicSession,
    this.semester,
    required this.subjectCode,
    this.subjectName,
    this.credits,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      department: json['department'] ?? '',
      academicSession: json['academicSession'] ?? '',
      semester: json['semester'],
      subjectCode: json['subjectCode'] ?? '',
      subjectName: json['subjectName'],
      credits: json['credits'] != null ? (json['credits'] as num).toDouble() : null,
    );
  }
}
