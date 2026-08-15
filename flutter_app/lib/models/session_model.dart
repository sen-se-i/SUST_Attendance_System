class SessionModel {
  final String sessionId;
  final String classId;
  final String status;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double radiusMeters;
  final DateTime startedAt;
  final DateTime expiresAt;

  SessionModel({
    required this.sessionId,
    required this.classId,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.radiusMeters,
    required this.startedAt,
    required this.expiresAt,
  });

  bool get isActive => status == 'ACTIVE' && DateTime.now().isBefore(expiresAt);

  int get remainingSeconds {
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      sessionId: json['sessionId'] ?? json['id'] ?? '',
      classId: json['classId'] ?? '',
      status: json['status'] ?? 'ENDED',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble() ?? 0.0,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 10.0,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : DateTime.now().add(const Duration(seconds: 150)),
    );
  }
}
