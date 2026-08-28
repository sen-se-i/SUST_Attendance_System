import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/user_model.dart';
import '../models/class_model.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';

class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? message;

  ApiResponse({required this.isSuccess, this.data, this.message});
}

class ApiService {
  static String _customBaseUrl = 'https://jarvis-att.onrender.com';

  static String get baseUrl => _customBaseUrl;
  static set baseUrl(String url) => _customBaseUrl = url;

  static Future<String> getDeviceInstallId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('jarvisatt.deviceInstallId');
    if (id == null) {
      final random = Random.secure();
      final values = List<int>.generate(16, (i) => random.nextInt(256));
      id = 'flutter-dev-' + values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString('jarvisatt.deviceInstallId', id);
    }
    return id;
  }

  static Map<String, String> _headers(String? token) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _tryDecode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static String _extractErrorMessage(http.Response response, String fallback) {
    if (response.statusCode == 503 || response.statusCode == 502 || response.statusCode == 504) {
      return 'Server is waking up / deploying on Render. Please wait 30-40 seconds and try again.';
    }
    if (response.statusCode == 403) {
      return 'Access forbidden (403). Invalid credentials or permissions.';
    }
    final decoded = _tryDecode(response.body);
    if (decoded is Map) {
      if (decoded['message'] != null) return decoded['message'].toString();
      if (decoded['error'] != null) return decoded['error'].toString();
    }
    if (response.body.isNotEmpty && response.body.length < 200) {
      return response.body;
    }
    return '$fallback (${response.statusCode})';
  }

  // -------------------------------------------------------------
  // AUTH
  // -------------------------------------------------------------
  static Future<ApiResponse<UserModel>> login(String emailOrRegNo, String password, {String? deviceInstallId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers(null),
        body: jsonEncode({
          'email': emailOrRegNo.trim(),
          'password': password,
          if (deviceInstallId != null) 'deviceInstallId': deviceInstallId,
        }),
      );

      if (response.statusCode == 200) {
        final body = _tryDecode(response.body);
        if (body == null) {
          return ApiResponse(isSuccess: false, message: 'Invalid server response');
        }
        final token = body['token'] ?? body['accessToken'] ?? '';
        final userJson = body['user'] ?? body;
        UserModel user = UserModel.fromJson(userJson, token);
        return ApiResponse(isSuccess: true, data: user);
      } else {
        return ApiResponse(isSuccess: false, message: _extractErrorMessage(response, 'Invalid credentials'));
      }
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Network error: $e');
    }
  }

  // -------------------------------------------------------------
  // ADMIN SERVICE
  // -------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> createStudentAdmin({
    required String token,
    required String registrationNo,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/students'),
        headers: _headers(token),
        body: jsonEncode({
          'registrationNo': registrationNo.trim(),
          'password': password.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(isSuccess: true, data: jsonDecode(response.body));
      } else {
        final err = jsonDecode(response.body);
        return ApiResponse(isSuccess: false, message: err['message'] ?? 'Failed to create student');
      }
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error creating student: $e');
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> createTeacherAdmin({
    required String token,
    required String email,
    required String password,
    required String department,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/teachers'),
        headers: _headers(token),
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password.trim(),
          'department': department.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(isSuccess: true, data: jsonDecode(response.body));
      } else {
        final err = jsonDecode(response.body);
        return ApiResponse(isSuccess: false, message: err['message'] ?? 'Failed to create teacher');
      }
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error creating teacher: $e');
    }
  }

  static Future<ApiResponse<List<Map<String, dynamic>>>> listTeachersAdmin(String token, {String? department}) async {
    try {
      String url = '$baseUrl/api/admin/teachers';
      if (department != null && department.isNotEmpty && department != 'All Departments') {
        url += '?department=${Uri.encodeComponent(department)}';
      }
      final response = await http.get(Uri.parse(url), headers: _headers(token));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return ApiResponse(isSuccess: true, data: list.cast<Map<String, dynamic>>());
      }
      return ApiResponse(isSuccess: false, message: 'Failed to load teachers');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error loading teachers: $e');
    }
  }

  static Future<ApiResponse<ClassModel>> createClassAdmin({
    required String token,
    required String department,
    required String academicSession,
    required String semester,
    required String subjectCode,
    required String subjectName,
    required double credits,
    required String teacherId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/classes'),
        headers: _headers(token),
        body: jsonEncode({
          'department': department,
          'academicSession': academicSession,
          'semester': semester,
          'subjectCode': subjectCode,
          'subjectName': subjectName,
          'credits': credits,
          'teacherId': teacherId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(isSuccess: true, data: ClassModel.fromJson(jsonDecode(response.body)));
      } else {
        final err = jsonDecode(response.body);
        return ApiResponse(isSuccess: false, message: err['message'] ?? 'Failed to create class');
      }
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error creating class: $e');
    }
  }

  static Future<ApiResponse<List<ClassModel>>> listAllClassesAdmin(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/classes'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return ApiResponse(isSuccess: true, data: list.map((item) => ClassModel.fromJson(item)).toList());
      }
      return ApiResponse(isSuccess: false, message: 'Failed to load admin classes');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error: $e');
    }
  }

  static Future<ApiResponse<void>> endClassAdmin(String token, String classId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/classes/$classId/end'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        return ApiResponse(isSuccess: true);
      }
      return ApiResponse(isSuccess: false, message: 'Failed to end class');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error: $e');
    }
  }

  static Future<ApiResponse<void>> adminResetPassword(String token, String identifier, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/users/reset-password'),
        headers: _headers(token),
        body: jsonEncode({
          'identifier': identifier.trim(),
          'newPassword': newPassword.trim(),
        }),
      );
      if (response.statusCode == 200) {
        return ApiResponse(isSuccess: true);
      }
      final err = jsonDecode(response.body);
      return ApiResponse(isSuccess: false, message: err['message'] ?? 'Failed to reset password');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error: $e');
    }
  }

  // -------------------------------------------------------------
  // TEACHER & STUDENT CLASSES
  // -------------------------------------------------------------
  static Future<ApiResponse<List<ClassModel>>> getClasses(String token, bool isTeacher) async {
    try {
      final endpoint = isTeacher ? '/api/classes' : '/api/classes/enrolled';
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        List<ClassModel> classes = list.map((item) => ClassModel.fromJson(item)).toList();
        return ApiResponse(isSuccess: true, data: classes);
      } else {
        return ApiResponse(isSuccess: false, message: 'Failed to load classes');
      }
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error loading classes: $e');
    }
  }

  // -------------------------------------------------------------
  // CLASS STUDENT MANAGEMENT (Add/Remove from Class)
  // -------------------------------------------------------------
  static Future<ApiResponse<List<Map<String, dynamic>>>> getClassStudents(String token, String classId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/classes/$classId/students'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return ApiResponse(isSuccess: true, data: list.cast<Map<String, dynamic>>());
      }
      return ApiResponse(isSuccess: false, message: 'Failed to load class students');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error: $e');
    }
  }

  static Future<ApiResponse<void>> addClassStudent(String token, String classId, String registrationNo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/classes/$classId/students'),
        headers: _headers(token),
        body: jsonEncode({'registrationNo': registrationNo.trim()}),
      );
      if (response.statusCode == 200) {
        return ApiResponse(isSuccess: true);
      }
      final err = jsonDecode(response.body);
      return ApiResponse(isSuccess: false, message: err['message'] ?? 'Failed to add student');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error: $e');
    }
  }

  static Future<ApiResponse<void>> removeClassStudent(String token, String classId, String registrationNo) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/classes/$classId/students/$registrationNo'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        return ApiResponse(isSuccess: true);
      }
      final err = jsonDecode(response.body);
      return ApiResponse(isSuccess: false, message: err['message'] ?? 'Failed to remove student');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error: $e');
    }
  }

  // -------------------------------------------------------------
  // ATTENDANCE MATRIX REPORT & CSV
  // -------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> getMatrixReport(String token, String classId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/classes/$classId/report/matrix'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        return ApiResponse(isSuccess: true, data: jsonDecode(response.body));
      }
      return ApiResponse(isSuccess: false, message: 'Failed to generate matrix report');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error: $e');
    }
  }

  static Future<ApiResponse<String>> downloadCsv(String token, String classId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/classes/$classId/report/csv'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        return ApiResponse(isSuccess: true, data: response.body);
      }
      return ApiResponse(isSuccess: false, message: 'Failed to download CSV');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error: $e');
    }
  }

  // -------------------------------------------------------------
  // GPS SESSION & ATTENDANCE
  // -------------------------------------------------------------
  static Future<ApiResponse<SessionModel>> startGpsSession({
    required String token,
    required String classId,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required DateTime capturedAt,
    required double radiusMeters,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sessions/start'),
        headers: _headers(token),
        body: jsonEncode({
          'classId': classId,
          'latitude': latitude,
          'longitude': longitude,
          'accuracyMeters': accuracyMeters,
          'capturedAt': capturedAt.toUtc().toIso8601String(),
          'radiusMeters': radiusMeters,
          'totalTicks': 150,
          'intervalSeconds': 1,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final session = SessionModel.fromJson(jsonDecode(response.body));
        return ApiResponse(isSuccess: true, data: session);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse(isSuccess: false, message: error['message'] ?? 'Failed to start session');
      }
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error starting session: $e');
    }
  }

  static Future<ApiResponse<void>> stopSession(String token, String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sessions/$sessionId/stop'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        return ApiResponse(isSuccess: true);
      }
      return ApiResponse(isSuccess: false, message: 'Failed to stop session');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error stopping session: $e');
    }
  }

  static Future<ApiResponse<SessionModel>> getActiveSession(String token, String classId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sessions/active?classId=$classId'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final session = SessionModel.fromJson(jsonDecode(response.body));
        return ApiResponse(isSuccess: true, data: session);
      }
      return ApiResponse(isSuccess: false, message: 'No active session');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error checking session');
    }
  }

  static Future<ApiResponse<AttendanceRecordModel>> claimAttendance({
    required String token,
    required String sessionId,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required DateTime capturedAt,
    required String deviceInstallId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/attendance/claim'),
        headers: _headers(token),
        body: jsonEncode({
          'sessionId': sessionId,
          'latitude': latitude,
          'longitude': longitude,
          'accuracyMeters': accuracyMeters,
          'capturedAt': capturedAt.toUtc().toIso8601String(),
          'deviceInstallId': deviceInstallId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final record = AttendanceRecordModel.fromJson(jsonDecode(response.body));
        return ApiResponse(isSuccess: true, data: record);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse(
          isSuccess: false,
          message: error['message'] ?? 'Attendance verification failed.',
        );
      }
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error claiming attendance: $e');
    }
  }

  static Future<ApiResponse<List<AttendanceRecordModel>>> getStudentHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/attendance/me'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        List<AttendanceRecordModel> records = list.map((x) => AttendanceRecordModel.fromJson(x)).toList();
        return ApiResponse(isSuccess: true, data: records);
      }
      return ApiResponse(isSuccess: false, message: 'Failed to load history');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error loading history: $e');
    }
  }

  static Future<ApiResponse<List<AttendanceRecordModel>>> getSessionRecords(String token, String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sessions/$sessionId/records'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        List<AttendanceRecordModel> records = list.map((x) => AttendanceRecordModel.fromJson(x)).toList();
        return ApiResponse(isSuccess: true, data: records);
      }
      return ApiResponse(isSuccess: false, message: 'Failed to load session records');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error loading records: $e');
    }
  }

  static Future<ApiResponse<List<AttendanceRecordModel>>> getClassHistory(String token, String classId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/attendance/classes/$classId'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        List<AttendanceRecordModel> records = list.map((x) => AttendanceRecordModel.fromJson(x)).toList();
        return ApiResponse(isSuccess: true, data: records);
      }
      return ApiResponse(isSuccess: false, message: 'Failed to load class history');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error loading class history: $e');
    }
  }

  static Future<ApiResponse<void>> joinClass(String token, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/classes/join'),
        headers: _headers(token),
        body: jsonEncode({'code': code}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(isSuccess: true);
      }
      final error = jsonDecode(response.body);
      return ApiResponse(isSuccess: false, message: error['message'] ?? 'Failed to join class');
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Error joining class: $e');
    }
  }
}
