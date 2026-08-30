import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../models/class_model.dart';
import '../models/attendance_model.dart';
import '../models/session_model.dart';
import '../widgets/location_radar_widget.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  List<ClassModel> _classes = [];
  bool _isLoadingClasses = false;
  ClassModel? _selectedClass;
  SessionModel? _activeSession;
  List<AttendanceRecordModel> _myHistory = [];
  bool _isClaiming = false;
  bool _hasAttendedCurrentSession = false;
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadEnrolledClasses();
    _loadHistory();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadEnrolledClasses() async {
    setState(() => _isLoadingClasses = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.getClasses(auth.token, false);
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

  Future<void> _loadHistory() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.getStudentHistory(auth.token);
    if (mounted && res.isSuccess && res.data != null) {
      setState(() {
        _myHistory = res.data!;
        if (_activeSession != null) {
          _hasAttendedCurrentSession = _myHistory.any((r) => r.sessionId == _activeSession!.sessionId);
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
          _hasAttendedCurrentSession = _myHistory.any((r) => r.sessionId == _activeSession!.sessionId);
        });
        _startTimer();
      } else {
        setState(() {
          _activeSession = null;
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
      } else {
        _timer?.cancel();
        setState(() {
          _activeSession = null;
        });
      }
    });
  }

  Future<void> _claimAttendance() async {
    if (_activeSession == null) return;
    setState(() => _isClaiming = true);

    final loc = await LocationService.getCurrentLocation(radiusMeters: _activeSession!.radiusMeters);
    if (loc.error != null) {
      setState(() => _isClaiming = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.error!),
          backgroundColor: const Color(0xFF222222),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
      return;
    }

    final deviceId = await ApiService.getDeviceInstallId();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.claimAttendance(
      token: auth.token,
      sessionId: _activeSession!.sessionId,
      latitude: loc.latitude,
      longitude: loc.longitude,
      accuracyMeters: loc.accuracyMeters,
      capturedAt: loc.capturedAt,
      deviceInstallId: deviceId,
    );

    setState(() => _isClaiming = false);
    if (!mounted) return;

    if (response.isSuccess) {
      setState(() {
        _hasAttendedCurrentSession = true;
      });
      _loadHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance recorded successfully!'),
          backgroundColor: Color(0xFF222222),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Attendance failed'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
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
          'STUDENT PORTAL',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5),
        ),
        actions: [

          InkWell(
            onTap: () {
              _loadEnrolledClasses();
              _loadHistory();
            },
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
          : RefreshIndicator(
              color: Colors.white,
              backgroundColor: Colors.black,
              onRefresh: () async {
                await _loadEnrolledClasses();
                await _loadHistory();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              border: Border.all(color: Colors.white),
                            ),
                            child: const Text('STUDENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.currentUser?.registrationNo ?? auth.currentUser?.email ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'AUTOMATIC ENROLLMENT ACTIVE',
                                  style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('AUTO-ENROLLED COURSES', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    if (_classes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D0D),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: const Column(
                          children: [
                            Text('NO ACTIVE COURSES ASSIGNED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                            SizedBox(height: 6),
                            Text(
                              'Courses will automatically appear here once created by faculty for your department & session.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else
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
                                _hasAttendedCurrentSession = false;
                              });
                              _checkActiveSession();
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    if (_activeSession != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D0D),
                          border: Border.all(color: const Color(0xFFFFFFFF), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'SESSION ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF222222),
                                    border: Border.all(color: Colors.white),
                                  ),
                                  child: Text(
                                    '${_remainingSeconds}S REMAINING',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141414),
                                border: Border.all(color: const Color(0xFF333333)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Flexible(
                                    child: Text('REQUIRED LOCATION TRACK:', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${_activeSession!.radiusMeters.toInt()} METERS', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (_hasAttendedCurrentSession)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141414),
                                  border: Border.all(color: Colors.white),
                                ),
                                child: const Text(
                                  'ATTENDANCE RECORDED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isClaiming ? null : _claimAttendance,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFFFFF),
                                    foregroundColor: const Color(0xFF000000),
                                    elevation: 0,
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  ),
                                  child: _isClaiming
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                        )
                                      : const Text(
                                          'GIVE ATTENDANCE (LOCATION TRACK)',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                                        ),
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D0D),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'NO ACTIVE ATTENDANCE SESSION',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Select a course above and wait for faculty to start a GPS geofenced session.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF777777), fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'MY ATTENDANCE LOG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            border: Border.all(color: const Color(0xFF444444)),
                          ),
                          child: Text(
                            '${_myHistory.length} TOTAL',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_myHistory.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D0D),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: const Text('No attendance history recorded yet.', style: TextStyle(color: Color(0xFF777777), fontSize: 12)),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _myHistory.length,
                        itemBuilder: (context, index) {
                          final item = _myHistory[index];
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
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A1A1A),
                                        border: Border.all(color: Colors.white),
                                      ),
                                      child: const Text('P', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.subjectCode.isNotEmpty ? item.subjectCode : 'Course Session',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'DIST: ${item.distanceMeters.toStringAsFixed(1)}m | ACC: ${item.accuracyMeters.toStringAsFixed(1)}m',
                                          style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  DateFormat('yyyy-MM-dd HH:mm').format(item.scannedAt.toLocal()),
                                  style: const TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
