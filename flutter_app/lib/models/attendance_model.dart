class AttendanceRecordModel {
  final String id;
  final String sessionId;
  final String classId;
  final String registrationNo;
  final String subjectCode;
  final double distanceMeters;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime scannedAt;

  AttendanceRecordModel({
    required this.id,
    required this.sessionId,
    required this.classId,
    required this.registrationNo,
    required this.subjectCode,
    required this.distanceMeters,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.scannedAt,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] ?? '',
      sessionId: json['sessionId'] ?? '',
      classId: json['classId'] ?? '',
      registrationNo: json['registrationNo'] ?? '',
      subjectCode: json['subjectCode'] ?? '',
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble() ?? 0.0,
      scannedAt: json['scannedAt'] != null ? DateTime.parse(json['scannedAt']) : DateTime.now(),
    );
  }
}
