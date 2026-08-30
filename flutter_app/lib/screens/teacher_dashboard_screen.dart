import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D0D),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _metricBox('LOCATION', '${_activeSession!.radiusMeters.toInt()} METERS'),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _metricBox('PRESENT STUDENTS', '${_sessionRecords.length}'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rec.registrationNo,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Distance: ${rec.distanceMeters.toStringAsFixed(1)}m from teacher',
                                          style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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

  Future<void> _exportPdf() async {
    if (_report == null) return;
    final report = _report!;

    final pdf = pw.Document();
    final sessions = (report['sessions'] as List?) ?? [];
    final studentRows = (report['studentRows'] ?? report['rows'] ?? []) as List;
    final counts = (report['sessionAttendanceCounts'] ?? report['sessionTotals'] ?? []) as List;

    String computeMark(double pct) {
      if (pct >= 95) return '10';
      if (pct >= 90) return '9';
      if (pct >= 85) return '8';
      if (pct >= 80) return '7';
      if (pct >= 75) return '6';
      if (pct >= 70) return '5';
      if (pct >= 65) return '4';
      if (pct >= 60) return '3';
      if (pct >= 50) return '0 (Eligible)';
      return 'INELIGIBLE';
    }

    final sessionHeaders = sessions.asMap().entries.map((entry) {
      final idx = entry.key;
      final s = entry.value;
      final raw = (s['startedAt'] ?? s['date'] ?? '').toString();
      try {
        return DateFormat('MM/dd').format(DateTime.parse(raw).toLocal());
      } catch (_) {
        return 'S${idx + 1}';
      }
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [

          pw.Text(
            'ATTENDANCE REPORT — ${report['classCode'] ?? ''} ${report['subjectName'] ?? report['subjectCode'] ?? ''}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Department: ${report['department'] ?? ''}   Session: ${report['academicSession'] ?? ''}   Semester: ${report['semester'] ?? ''}   Teacher: ${report['teacherName'] ?? ''}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Total Sessions: ${report['totalSessions'] ?? 0}   Total Students: ${report['totalStudents'] ?? 0}   Average Attendance: ${report['averageAttendancePercentage'] ?? 0}%',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 12),

          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(90),
              ...{for (var i = 0; i < sessions.length; i++) i + 1: const pw.FixedColumnWidth(28)},
              sessions.length + 1: const pw.FixedColumnWidth(42),
              sessions.length + 2: const pw.FixedColumnWidth(55),
            },
            children: [

              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _pdfCell('REGISTRATION NO', bold: true, fontSize: 7),
                  ...sessionHeaders.map((h) => _pdfCell(h, bold: true, fontSize: 7)),
                  _pdfCell('TOTAL/%', bold: true, fontSize: 7),
                  _pdfCell('MARKS', bold: true, fontSize: 7),
                ],
              ),

              ...studentRows.map((r) {
                final reg = r['registrationNo']?.toString() ?? '';
                final dynamic attData = r['attendance'] ?? r['attendanceMatrix'];
                final total = r['totalAttended'] ?? r['totalPresent'] ?? 0;
                final pct = (r['percentage'] as num?)?.toDouble() ?? 0.0;
                final mark = (r['attendanceMark']?.toString().isNotEmpty ?? false)
                    ? r['attendanceMark'].toString()
                    : computeMark(pct);
                final isIneligible = mark.toUpperCase().contains('INELIGIBLE');

                return pw.TableRow(
                  decoration: isIneligible ? const pw.BoxDecoration(color: PdfColors.red50) : null,
                  children: [
                    _pdfCell(reg, fontSize: 7),
                    ...sessions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      final sId = s['sessionId']?.toString() ?? s['id']?.toString() ?? '';
                      bool present = false;
                      if (attData is List && i < attData.length) {
                        present = attData[i] == true;
                      } else if (attData is Map) {
                        present = attData[sId] == true;
                      }

                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Center(
                          child: pw.Text(
                            present ? 'P' : 'A',
                            style: pw.TextStyle(
                              fontSize: 7,
                              color: present ? PdfColors.green700 : PdfColors.red700,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                    _pdfCell('$total (${pct.toStringAsFixed(0)}%)', fontSize: 7),
                    _pdfCell(mark, bold: true, fontSize: 7,
                        color: isIneligible ? PdfColors.red700 : (pct >= 75 ? PdfColors.green700 : PdfColors.orange700)),
                  ],
                );
              }),

              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _pdfCell('TOTAL PRESENT', bold: true, fontSize: 7),
                  ...List.generate(sessions.length, (i) {
                    int count = 0;
                    if (i < counts.length) {
                      final item = counts[i];
                      if (item is num) {
                        count = item.toInt();
                      } else if (item is Map) {
                        count = (item['presentCount'] ?? item['attendanceCount'] ?? 0) as int;
                      }
                    }
                    return _pdfCell('$count', bold: true, fontSize: 7);
                  }),
                  _pdfCell('-', fontSize: 7),
                  _pdfCell('-', fontSize: 7),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          pw.Text('ATTENDANCE MARKS GRADING POLICY:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(100),
              1: pw.FixedColumnWidth(80),
              2: pw.FixedColumnWidth(160),
            },
            children: [
              pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey300), children: [
                _pdfCell('Attendance %', bold: true, fontSize: 8),
                _pdfCell('Marks', bold: true, fontSize: 8),
                _pdfCell('Exam Status', bold: true, fontSize: 8),
              ]),
              for (final row in [
                ['95 – 100 %', '10', 'Eligible'],
                ['90 – 94 %', '9', 'Eligible'],
                ['85 – 89 %', '8', 'Eligible'],
                ['80 – 84 %', '7', 'Eligible'],
                ['75 – 79 %', '6', 'Eligible'],
                ['70 – 74 %', '5', 'Eligible'],
                ['65 – 69 %', '4', 'Eligible'],
                ['60 – 64 %', '3', 'Eligible'],
                ['50 – 59 %', '0', 'Eligible (0 marks)'],
                ['0 – 49 %', 'INELIGIBLE', 'Cannot sit for exam'],
              ])
                pw.TableRow(children: [
                  _pdfCell(row[0], fontSize: 8),
                  _pdfCell(row[1], fontSize: 8, bold: row[1] == 'INELIGIBLE'),
                  _pdfCell(row[2], fontSize: 8),
                ]),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (fmt) async => pdf.save());
  }

  static pw.Widget _pdfCell(String text, {bool bold = false, double fontSize = 8, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Color(0xFF333333))),
      title: const Text(
        'MATRIX ATTENDANCE REPORT',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.8),
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

                        Row(
                          children: [
                            Expanded(child: _summaryCard('SESSIONS', '${_report!['totalSessions'] ?? 0}')),
                            const SizedBox(width: 6),
                            Expanded(child: _summaryCard('STUDENTS', '${_report!['totalStudents'] ?? 0}')),
                            const SizedBox(width: 6),
                            Expanded(child: _summaryCard('AVG ATT %', '${_report!['averageAttendancePercentage'] ?? 0}%')),
                          ],
                        ),
                        const SizedBox(height: 16),

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
          onPressed: _exportPdf,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
          child: const Text('EXPORT PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CLOSE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  (String, Color) _computeMarkColor(double pct) {
    if (pct >= 95) return ('10', Colors.greenAccent);
    if (pct >= 90) return ('9', Colors.greenAccent);
    if (pct >= 85) return ('8', Colors.greenAccent);
    if (pct >= 80) return ('7', const Color(0xFF80FF80));
    if (pct >= 75) return ('6', const Color(0xFFB0FF70));
    if (pct >= 70) return ('5', Colors.yellowAccent);
    if (pct >= 65) return ('4', Colors.orangeAccent);
    if (pct >= 60) return ('3', Colors.orange);
    if (pct >= 50) return ('0 (Eligible)', Colors.orange);
    return ('INELIGIBLE', Colors.redAccent);
  }

  Widget _summaryCard(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF161616), border: Border.all(color: const Color(0xFF333333))),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMatrixTable(Map<String, dynamic> data) {
    final List sessions = (data['sessions'] as List?) ?? [];
    final List studentRows = (data['studentRows'] ?? data['rows'] ?? []) as List;
    final List counts = (data['sessionAttendanceCounts'] ?? data['sessionTotals'] ?? []) as List;

    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        alignment: Alignment.center,
        child: const Text(
          'No attendance sessions conducted yet for this class.',
          style: TextStyle(color: Color(0xFF888888), fontSize: 12),
        ),
      );
    }

    return DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFF1E1E1E)),
      dataRowColor: WidgetStateProperty.all(const Color(0xFF0D0D0D)),
      border: TableBorder.all(color: const Color(0xFF2A2A2A)),
      columns: [
        const DataColumn(label: Text('REGISTRATION NO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
        ...sessions.asMap().entries.map((entry) {
          final idx = entry.key;
          final s = entry.value;
          final raw = (s['startedAt'] ?? s['date'] ?? '').toString();
          String formatted;
          try {
            formatted = DateFormat('MM-dd HH:mm').format(DateTime.parse(raw).toLocal());
          } catch (_) {
            formatted = 'S${idx + 1}';
          }
          return DataColumn(
            label: Text(
              formatted,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          );
        }),
        const DataColumn(label: Text('TOTAL / %', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
        const DataColumn(label: Text('MARKS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
      ],
      rows: [
        ...studentRows.map((r) {
          final reg = r['registrationNo']?.toString() ?? '';
          final dynamic attData = r['attendance'] ?? r['attendanceMatrix'];
          final totalPresent = r['totalAttended'] ?? r['totalPresent'] ?? 0;
          final pct = (r['percentage'] as num?)?.toDouble() ?? 0.0;

          List<DataCell> cells = [
            DataCell(Text(reg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
          ];

          for (var i = 0; i < sessions.length; i++) {
            final s = sessions[i];
            final sId = s['sessionId']?.toString() ?? s['id']?.toString() ?? '';
            bool isPresent = false;
            if (attData is List && i < attData.length) {
              isPresent = attData[i] == true;
            } else if (attData is Map) {
              isPresent = attData[sId] == true;
            }

            cells.add(
              DataCell(
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
              ),
            );
          }

          cells.add(DataCell(Text('$totalPresent (${pct.toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))));

          final markStr = (r['attendanceMark']?.toString().isNotEmpty ?? false)
              ? r['attendanceMark'].toString()
              : _computeMarkColor(pct).$1;
          final markColor = _computeMarkColor(pct).$2;

          cells.add(DataCell(
            Text(markStr,
              style: TextStyle(color: markColor, fontWeight: FontWeight.bold, fontSize: 11)),
          ));

          return DataRow(cells: cells);
        }),

        DataRow(
          color: WidgetStateProperty.all(const Color(0xFF1E1E1E)),
          cells: [
            const DataCell(Text('TOTAL PRESENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11))),
            ...List.generate(sessions.length, (idx) {
              int count = 0;
              if (idx < counts.length) {
                final item = counts[idx];
                if (item is num) {
                  count = item.toInt();
                } else if (item is Map) {
                  count = (item['presentCount'] ?? item['attendanceCount'] ?? 0) as int;
                }
              }
              return DataCell(Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)));
            }),
            const DataCell(Text('-', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            const DataCell(Text('-', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
      ],
    );
  }
}

