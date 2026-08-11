import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/class_model.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/radius_slider_widget.dart';
import '../widgets/location_radar_widget.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  List<ClassModel> _classes = [];
  ClassModel? _selectedClass;
  SessionModel? _activeSession;
  List<AttendanceRecordModel> _sessionRecords = [];
  double _selectedRadius = 10.0;
  bool _isLoadingClasses = true;
  bool _isStartingSession = false;
  Timer? _timer;
  int _remainingSeconds = 150;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.getClasses(auth.currentUser!.token, true);
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

  Future<void> _checkActiveSession() async {
    if (_selectedClass == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.getActiveSession(auth.currentUser!.token, _selectedClass!.id);
    if (response.isSuccess && response.data != null && response.data!.isActive) {
      setState(() {
        _activeSession = response.data!;
        _remainingSeconds = _activeSession!.remainingSeconds;
      });
      _startTimer();
      _fetchSessionRecords();
    }
  }

  Future<void> _fetchSessionRecords() async {
    if (_selectedClass == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.getClassHistory(auth.currentUser!.token, _selectedClass!.id);
    if (response.isSuccess && response.data != null) {
      setState(() {
        if (_activeSession != null) {
          _sessionRecords = response.data!
              .where((r) => r.sessionId == _activeSession!.sessionId)
              .toList();
        } else {
          _sessionRecords = response.data!;
        }
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
        _fetchSessionRecords();
      } else {
        _timer?.cancel();
        setState(() {
          _activeSession = null;
        });
      }
    });
  }

  Future<void> _startSession() async {
    if (_selectedClass == null) return;
    setState(() => _isStartingSession = true);

    // Get teacher's current GPS position
    final loc = await LocationService.getCurrentLocation();
    if (loc.error != null) {
      setState(() => _isStartingSession = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.error!), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.startGpsSession(
      token: auth.currentUser!.token,
      classId: _selectedClass!.id,
      latitude: loc.latitude,
      longitude: loc.longitude,
      radiusMeters: _selectedRadius,
    );

    setState(() => _isStartingSession = false);

    if (response.isSuccess && response.data != null) {
      setState(() {
        _activeSession = response.data;
        _remainingSeconds = 150;
        _sessionRecords = [];
      });
      _startTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GPS Session Started! Radius: ${_selectedRadius.toInt()}m'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Failed to start session'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _stopSession() async {
    if (_activeSession == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await ApiService.stopSession(auth.currentUser!.token, _activeSession!.sessionId);
    _timer?.cancel();
    setState(() {
      _activeSession = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session Ended'), backgroundColor: Colors.orange),
    );
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
            Icon(Icons.radar, color: Color(0xFF818CF8)),
            SizedBox(width: 8),
            Text(
              'SWE-Attendance (Teacher)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
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
                  // Class Selector Dropdown
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
                              '${c.subjectCode} - ${c.department} (${c.code})',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 20),

                  // Session Control Card
                  if (_activeSession == null) ...[
                    // Radius Selection Widget
                    RadiusSliderWidget(
                      selectedRadius: _selectedRadius,
                      onChanged: (val) => setState(() => _selectedRadius = val),
                    ),
                    const SizedBox(height: 20),

                    // Start GPS Session Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isStartingSession ? null : _startSession,
                        icon: _isStartingSession
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.play_arrow_rounded, size: 28),
                        label: Text(
                          _isStartingSession ? 'Capturing Location...' : 'Start GPS Session (${_selectedRadius.toInt()}m)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Active Session Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF6366F1)),
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
                                    'ACTIVE SESSION',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
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
                                child: Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, color: Colors.redAccent, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_remainingSeconds}s',
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
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
                              _metricBadge('Radius', '${_activeSession!.radiusMeters.toInt()} meters'),
                              _metricBadge('Checked In', '${_sessionRecords.length} Students'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _stopSession,
                              icon: const Icon(Icons.stop_circle_rounded, color: Colors.redAccent),
                              label: const Text('End Session Now', style: TextStyle(color: Colors.redAccent)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Attendance Live Feed Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _activeSession != null ? 'Live Attendance Feed' : 'Class Attendance Log',
                        style: const TextStyle(
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
                          '${_sessionRecords.length} Present',
                          style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_sessionRecords.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF181829),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.person_search_rounded, color: Colors.grey, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'No student check-ins recorded yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sessionRecords.length,
                      itemBuilder: (context, index) {
                        final rec = _sessionRecords[index];
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
                                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
                                    child: const Icon(Icons.person_rounded, color: Color(0xFF818CF8)),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAlignment.start,
                                    children: [
                                      Text(
                                        'Reg: ${rec.registrationNo}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Distance: ${rec.distanceMeters.toStringAsFixed(1)}m from teacher',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: const Text(
                                  'VERIFIED',
                                  style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
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

  Widget _metricBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
