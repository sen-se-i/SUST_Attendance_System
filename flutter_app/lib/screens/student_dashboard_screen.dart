import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/class_model.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/location_radar_widget.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  List<ClassModel> _classes = [];
  ClassModel? _selectedClass;
  SessionModel? _activeSession;
  List<AttendanceRecordModel> _myHistory = [];
  bool _isLoadingClasses = true;
  bool _isClaiming = false;
  bool _hasAttendedCurrentSession = false;
  AttendanceRecordModel? _lastResult;
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.getClasses(auth.currentUser!.token, false);
    setState(() {
      _isLoadingClasses = false;
      if (response.isSuccess && response.data != null) {
        _classes = response.data!;
        if (_classes.isNotEmpty) {
          _selectedClass = _classes.first;
          _checkActiveSession();
        }
      }
    });
  }

  Future<void> _loadHistory() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.getStudentHistory(auth.currentUser!.token);
    if (response.isSuccess && response.data != null) {
      setState(() {
        _myHistory = response.data!;
      });
    }
  }

  Future<void> _checkActiveSession() async {
    if (_selectedClass == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.getActiveSession(auth.currentUser!.token, _selectedClass!.id);
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

    // Get phone's current GPS location
    final loc = await LocationService.getCurrentLocation();
    if (loc.error != null) {
      setState(() => _isClaiming = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.error!), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.claimAttendance(
      token: auth.currentUser!.token,
      sessionId: _activeSession!.sessionId,
      latitude: loc.latitude,
      longitude: loc.longitude,
      deviceInstallId: 'flutter-device-id-${auth.currentUser!.id.substring(0, 8)}',
    );

    setState(() => _isClaiming = false);

    if (response.isSuccess && response.data != null) {
      setState(() {
        _hasAttendedCurrentSession = true;
        _lastResult = response.data;
      });
      _loadHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance Registered! Distance: ${response.data!.distanceMeters.toStringAsFixed(1)}m'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Attendance verification failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181829),
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.location_on, color: Color(0xFF38BDF8)),
            SizedBox(width: 8),
            Text(
              'SWE-Attendance (Student)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF818CF8)),
            onPressed: () {
              _checkActiveSession();
              _loadHistory();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: _isLoadingClasses
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  // Student Info Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181829),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2D2D44)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF38BDF8).withOpacity(0.2),
                          child: const Icon(Icons.badge, color: Color(0xFF38BDF8)),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAlignment.start,
                          children: [
                            Text(
                              auth.currentUser?.email ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Reg No: ${auth.currentUser?.registrationNo ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[400], fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Class Selector Dropdown
                  if (_classes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181829),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2D2D44)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ClassModel>(
                          value: _selectedClass,
                          dropdownColor: const Color(0xFF181829),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF818CF8)),
                          items: _classes.map((c) {
                            return DropdownMenuItem<ClassModel>(
                              value: c,
                              child: Text(
                                '${c.subjectCode} - ${c.department}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 20),

                  // Session Action Card
                  if (_activeSession != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF6366F1)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.sensors_rounded, color: Colors.greenAccent),
                                  SizedBox(width: 8),
                                  Text(
                                    'SESSION IN PROGRESS',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.redAccent),
                                ),
                                child: Text(
                                  '${_remainingSeconds}s remaining',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
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

                          if (_hasAttendedCurrentSession)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                                  SizedBox(width: 10),
                                  Text(
                                    'Attendance Verified & Recorded!',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _isClaiming ? null : _claimAttendance,
                                icon: _isClaiming
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.touch_app_rounded, size: 28),
                                label: Text(
                                  _isClaiming ? 'Verifying Location...' : 'Give Attendance (GPS)',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF181829),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2D2D44)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.location_off_rounded, color: Colors.grey, size: 44),
                          const SizedBox(height: 12),
                          const Text(
                            'No Active Attendance Session',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Wait for your teacher to launch a GPS attendance session.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Personal Attendance History Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Attendance History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25253A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_myHistory.length} Sessions',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_myHistory.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF181829),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('No attendance history found.', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _myHistory.length,
                      itemBuilder: (context, index) {
                        final item = _myHistory[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181829),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF2D2D44)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.green.withOpacity(0.2),
                                    child: const Icon(Icons.check_rounded, color: Colors.green),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAlignment.start,
                                    children: [
                                      Text(
                                        item.subjectCode.isNotEmpty ? item.subjectCode : 'Class Session',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Distance: ${item.distanceMeters.toStringAsFixed(1)}m from teacher',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                '${item.scannedAt.hour.toString().padLeft(2, '0')}:${item.scannedAt.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
