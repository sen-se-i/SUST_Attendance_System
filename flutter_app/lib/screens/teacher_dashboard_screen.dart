import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../models/class_model.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../widgets/location_radar_widget.dart';
import '../widgets/radius_slider_widget.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  List<ClassModel> _classes = [];
  bool _isLoadingClasses = false;
  ClassModel? _selectedClass;

  // Active Session State
  SessionModel? _activeSession;
  List<AttendanceRecordModel> _sessionRecords = [];
  Timer? _timer;
  int _remainingSeconds = 0;
  double _selectedRadius = 30.0;
  bool _isStartingSession = false;

  @override
  void initState() {
    super.initState();
    _loadTeacherClasses();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTeacherClasses() async {
    setState(() => _isLoadingClasses = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.getClasses(auth.token, true);
    if (mounted) {
      setState(() {
        _isLoadingClasses = false;
        if (res.isSuccess && res.data != null) {
          // Filter only ACTIVE classes assigned to teacher
          _classes = res.data!.where((c) => c.status == null || c.status!.toUpperCase() == 'ACTIVE').toList();
          if (_classes.isNotEmpty && _selectedClass == null) {
            _selectedClass = _classes.first;
            _checkActiveSession();
          }
        }
      });
    }
  }

  Future<void> _checkActiveSession() async {
    if (_selectedClass == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.getActiveSession(auth.token, _selectedClass!.id);
    if (mounted) {
      if (response.isSuccess && response.data != null && response.data!.isActive) {
        setState(() {
          _activeSession = response.data!;
          _remainingSeconds = _activeSession!.remainingSeconds;
        });
        _startTimer();
        _loadSessionRecords();
      } else {
        setState(() {
          _activeSession = null;
          _sessionRecords = [];
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds % 3 == 0) {
          _loadSessionRecords();
        }
      } else {
        _timer?.cancel();
        setState(() {
          _activeSession = null;
        });
      }
    });
  }

  Future<void> _loadSessionRecords() async {
    if (_activeSession == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.getSessionRecords(auth.token, _activeSession!.sessionId);
    if (mounted && res.isSuccess && res.data != null) {
      setState(() {
        _sessionRecords = res.data!;
      });
    }
  }

  Future<void> _startSession() async {
    if (_selectedClass == null) {
      _showToast('Please select a class first.');
      return;
    }
    setState(() => _isStartingSession = true);

    final loc = await LocationService.getCurrentLocation(radiusMeters: _selectedRadius);
    if (loc.error != null) {
      setState(() => _isStartingSession = false);
      _showToast(loc.error!, isError: true);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.startGpsSession(
      token: auth.token,
      classId: _selectedClass!.id,
      latitude: loc.latitude,
      longitude: loc.longitude,
      accuracyMeters: loc.accuracyMeters,
      capturedAt: loc.capturedAt,
      radiusMeters: _selectedRadius,
    );

    setState(() => _isStartingSession = false);

    if (response.isSuccess && response.data != null) {
      setState(() {
        _activeSession = response.data!;
        _remainingSeconds = _activeSession!.remainingSeconds;
        _sessionRecords = [];
      });
      _startTimer();
      _showToast('GPS Session started (${_selectedRadius.toInt()}m radius)');
    } else {
      _showToast(response.message ?? 'Failed to start session', isError: true);
    }
  }

  Future<void> _stopSession() async {
    if (_activeSession == null) return;
    _timer?.cancel();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await ApiService.stopSession(auth.token, _activeSession!.sessionId);
    if (mounted) {
      setState(() {
        _activeSession = null;
      });
      _showToast('Attendance session stopped.');
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF222222),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  // -------------------------------------------------------------
  // DIALOG: MANAGE CLASS STUDENTS (ADD / REMOVE)
  // -------------------------------------------------------------
  void _openManageStudentsDialog() async {
    if (_selectedClass == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => _ClassStudentsDialog(
        classItem: _selectedClass!,
        token: auth.token,
      ),
    );
  }

  // -------------------------------------------------------------
  // DIALOG: MATRIX ATTENDANCE REPORT & CSV EXPORT
  // -------------------------------------------------------------
  void _openMatrixReportDialog() async {
    if (_selectedClass == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => _MatrixReportDialog(
        classItem: _selectedClass!,
        token: auth.token,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
        title: const Text(
          'TEACHER PORTAL',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5),
        ),
        actions: [
          // Text box button: RELOAD
          InkWell(
            onTap: () => _loadTeacherClasses(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                border: Border.all(color: const Color(0xFF444444)),
              ),
              child: const Text('RELOAD', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ),
          // Text box button: LOGOUT
          InkWell(
            onTap: () => auth.logout(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF220000),
                border: Border.all(color: Colors.redAccent),
              ),
              child: const Text('LOGOUT', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
      body: _isLoadingClasses
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : (_classes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('NO ASSIGNED CLASSES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Please contact Admin to assign courses to your faculty account.', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Class Selector Dropdown - Sharp Square
                      const Text('SELECT ASSIGNED CLASS', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D0D),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ClassModel>(
                            value: _selectedClass,
                            dropdownColor: const Color(0xFF141414),
                            isExpanded: true,
                            items: _classes.map((c) {
                              return DropdownMenuItem<ClassModel>(
                                value: c,
                                child: Text(
                                  '${c.subjectCode} - ${c.subjectName ?? c.department} [${c.academicSession}]',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedClass = val;
                                _activeSession = null;
                                _sessionRecords = [];
                              });
                              _checkActiveSession();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Action Buttons: Manage Students & Matrix Report (Clean Text Buttons)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _openManageStudentsDialog,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFF444444)),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('STUDENTS (ENROLLMENT)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _openMatrixReportDialog,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFF444444)),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('MATRIX REPORT (CSV)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // GPS Session Control
                      if (_activeSession == null) ...[
                        RadiusSliderWidget(
                          selectedRadius: _selectedRadius,
                          onChanged: (val) => setState(() => _selectedRadius = val),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isStartingSession ? null : _startSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            child: _isStartingSession
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                : Text(
                                    'START GPS ATTENDANCE (${_selectedRadius.toInt()}M)',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                                  ),
                          ),
                        ),
                      ] else ...[
                        // Active Session Running Box
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D0D),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'SESSION ACTIVE',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF222222),
                                      border: Border.all(color: Colors.white),
                                    ),
                                    child: Text(
                                      '${_remainingSeconds}S REMAINING',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              LocationRadarWidget(
                                isScanning: true,
                                radiusMeters: _activeSession!.radiusMeters,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _metricBox('GEOFENCE', '${_activeSession!.radiusMeters.toInt()}M'),
                                  _metricBox('PRESENT', '${_sessionRecords.length} STUDENTS'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton(
                                  onPressed: _stopSession,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.redAccent),
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  ),
                                  child: const Text('STOP SESSION NOW', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Live Check-ins Feed
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'LIVE ATTENDANCE FEED',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              border: Border.all(color: const Color(0xFF444444)),
                            ),
                            child: Text(
                              '${_sessionRecords.length} RECORDED',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_sessionRecords.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D0D),
                            border: Border.all(color: const Color(0xFF2A2A2A)),
                          ),
                          child: const Text('No student check-ins recorded in current session.', style: TextStyle(color: Color(0xFF777777), fontSize: 12)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _sessionRecords.length,
                          itemBuilder: (context, index) {
                            final rec = _sessionRecords[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D0D0D),
                                border: Border.all(color: const Color(0xFF2A2A2A)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rec.registrationNo,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Distance: ${rec.distanceMeters.toStringAsFixed(1)}m from teacher',
                                        style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFF1A1A1A), border: Border.all(color: Colors.white)),
                                    child: const Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                )),
    );
  }

  Widget _metricBox(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// CLASS STUDENTS MANAGEMENT DIALOG (ADD / REMOVE STUDENTS)
// -------------------------------------------------------------
class _ClassStudentsDialog extends StatefulWidget {
  final ClassModel classItem;
  final String token;

  const _ClassStudentsDialog({Key? key, required this.classItem, required this.token}) : super(key: key);

  @override
  State<_ClassStudentsDialog> createState() => _ClassStudentsDialogState();
}

class _ClassStudentsDialogState extends State<_ClassStudentsDialog> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  final _addRegController = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getClassStudents(widget.token, widget.classItem.id);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.isSuccess && res.data != null) {
          _students = res.data!;
        }
      });
    }
  }

  Future<void> _handleAddStudent() async {
    final reg = _addRegController.text.trim();
    if (reg.isEmpty) return;

    setState(() => _isAdding = true);
    final res = await ApiService.addClassStudent(widget.token, widget.classItem.id, reg);
    setState(() => _isAdding = false);

    if (res.isSuccess) {
      _addRegController.clear();
      _loadStudents();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student $reg added to class!'),
          backgroundColor: const Color(0xFF222222),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Failed to add student'),
          backgroundColor: Colors.redAccent,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  Future<void> _handleRemoveStudent(String reg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Color(0xFF333333))),
        title: Text('REMOVE $reg?', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
        content: Text('Removing $reg will unenroll them and delete their attendance records for this class.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('REMOVE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.removeClassStudent(widget.token, widget.classItem.id, reg);
      if (res.isSuccess) {
        _loadStudents();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student $reg removed from class'),
            backgroundColor: const Color(0xFF222222),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Color(0xFF333333))),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ENROLLED STUDENTS (${_students.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text('${widget.classItem.subjectCode} • ${widget.classItem.academicSession}', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add Student Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addRegController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Reg No (e.g. 2023831099)',
                      filled: true,
                      fillColor: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isAdding ? null : _handleAddStudent,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                  child: _isAdding
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('+ ADD', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Students List
            SizedBox(
              height: 300,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : (_students.isEmpty
                      ? const Center(child: Text('No students enrolled in this class.', style: TextStyle(color: Color(0xFF888888))))
                      : ListView.builder(
                          itemCount: _students.length,
                          itemBuilder: (ctx, idx) {
                            final st = _students[idx];
                            final reg = st['registrationNo']?.toString() ?? 'N/A';
                            final totalAttended = st['attendedSessions'] ?? 0;
                            final attPct = st['attendancePercentage'] ?? 0.0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(color: const Color(0xFF0D0D0D), border: Border.all(color: const Color(0xFF222222))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(reg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text('Attended: $totalAttended ($attPct%)', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () => _handleRemoveStudent(reg),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF220000),
                                        border: Border.all(color: Colors.redAccent),
                                      ),
                                      child: const Text('REMOVE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CLOSE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// MATRIX ATTENDANCE REPORT & CSV EXPORT DIALOG
// -------------------------------------------------------------
class _MatrixReportDialog extends StatefulWidget {
  final ClassModel classItem;
  final String token;

  const _MatrixReportDialog({Key? key, required this.classItem, required this.token}) : super(key: key);

  @override
  State<_MatrixReportDialog> createState() => _MatrixReportDialogState();
}

class _MatrixReportDialogState extends State<_MatrixReportDialog> {
  Map<String, dynamic>? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getMatrixReport(widget.token, widget.classItem.id);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.isSuccess && res.data != null) {
          _report = res.data;
        }
      });
    }
  }

  Future<void> _copyCsv() async {
    final res = await ApiService.downloadCsv(widget.token, widget.classItem.id);
    if (res.isSuccess && res.data != null) {
      await Clipboard.setData(ClipboardData(text: res.data!));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV Report copied to clipboard!'),
          backgroundColor: Color(0xFF222222),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Color(0xFF333333))),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('MATRIX ATTENDANCE REPORT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          InkWell(
            onTap: _copyCsv,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), border: Border.all(color: Colors.white)),
              child: const Text('COPY CSV', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : (_report == null
                ? const Center(child: Text('No attendance records to generate report.', style: TextStyle(color: Color(0xFF888888))))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _summaryCard('SESSIONS', '${_report!['totalSessions'] ?? 0}'),
                            _summaryCard('STUDENTS', '${_report!['totalStudents'] ?? 0}'),
                            _summaryCard('AVG ATT %', '${_report!['averageAttendancePercentage'] ?? 0}%'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Matrix Table View
                        const Text('ATTENDANCE MATRIX (P: Present, A: Absent)', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _buildMatrixTable(_report!),
                        ),
                      ],
                    ),
                  )),
      ),
      actions: [
        ElevatedButton(
          onPressed: _copyCsv,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
          child: const Text('COPY / EXPORT CSV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CLOSE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF161616), border: Border.all(color: const Color(0xFF333333))),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMatrixTable(Map<String, dynamic> data) {
    final List sessions = data['sessions'] ?? [];
    final List studentRows = data['rows'] ?? [];
    final List totals = data['sessionTotals'] ?? [];

    return DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFF1E1E1E)),
      dataRowColor: WidgetStateProperty.all(const Color(0xFF0D0D0D)),
      border: TableBorder.all(color: const Color(0xFF2A2A2A)),
      columns: [
        const DataColumn(label: Text('REGISTRATION NO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
        ...sessions.map((s) => DataColumn(
              label: Text(
                DateFormat('MM-dd HH:mm').format(DateTime.parse(s['date'] ?? DateTime.now().toIso8601String()).toLocal()),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            )),
        const DataColumn(label: Text('TOTAL / %', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
      ],
      rows: [
        ...studentRows.map((r) {
          final reg = r['registrationNo']?.toString() ?? '';
          final Map matrix = r['attendanceMatrix'] ?? {};
          final totalPresent = r['totalPresent'] ?? 0;
          final pct = r['percentage'] ?? 0.0;

          return DataRow(cells: [
            DataCell(Text(reg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
            ...sessions.map((s) {
              final sId = s['sessionId']?.toString() ?? '';
              final isPresent = matrix[sId] == true;
              return DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPresent ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                    border: Border.all(color: isPresent ? Colors.green : Colors.redAccent),
                  ),
                  child: Text(
                    isPresent ? 'P' : 'A',
                    style: TextStyle(color: isPresent ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              );
            }),
            DataCell(Text('$totalPresent (${pct.toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
          ]);
        }),
        // Bottom Footer Row with Totals
        DataRow(
          color: WidgetStateProperty.all(const Color(0xFF1E1E1E)),
          cells: [
            const DataCell(Text('TOTAL PRESENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11))),
            ...totals.map((t) => DataCell(Text('${t['presentCount'] ?? 0}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)))),
            const DataCell(Text('-', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
      ],
    );
  }
}
