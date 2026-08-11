import 'dart:convert';
import 'package:http/http.dart' as http;
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
  static String baseUrl = 'http://localhost:8080';

  static Map<String, String> _headers(String? token) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<ApiResponse<UserModel>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers(null),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final token = body['token'] ?? body['accessToken'] ?? '';
        final userJson = body['user'] ?? body;
        UserModel user = UserModel.fromJson(userJson, token);
        return ApiResponse(isSuccess: true, data: user);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse(isSuccess: false, message: error['message'] ?? 'Login failed');
      }
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Network error: $e');
    }
  }

  static Future<ApiResponse<UserModel>> register({
    required String email,
    required String password,
    required String role,
    String? registrationNo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: _headers(null),
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
          'registrationNo': registrationNo,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return login(email, password);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse(isSuccess: false, message: error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      return ApiResponse(isSuccess: false, message: 'Network error: $e');
    }
  }

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

  static Future<ApiResponse<SessionModel>> startGpsSession({
    required String token,
    required String classId,
    required double latitude,
    required double longitude,
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
}
