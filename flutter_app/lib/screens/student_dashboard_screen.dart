import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/class_model.dart';
import '../models/attendance_model.dart';
import '../models/session_model.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override:
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  List<ClassModel> _classes = [];
  bool _isLoading = false;
  ClassModel? _selectedClass;

  List<AttendanceRecordModel> _myRecords = [];

  @override
  void initState() {
    super.initState();
    _loadEnrolledClasses();
  }

  Future<void> _loadEnrolledClasses() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.getClasses(auth.token, false);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.isSuccess && res.data != null) {
          _classes = res.data!;
        }
      });
    }
  }

  Future<void> _loadClassDetail(ClassModel item) async {
    setState(() {
      _selectedClass = item;
      _isLoading = true;
    });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.getStudentHistory(auth.token);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.isSuccess && res.data != null) {
          _myRecords = res.data!.where((r) => r.classId == item.id).toList();
        }
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
    final loc = await LocationService.getCurrentLocation(radiusMeters: _activeSession!.radiusMeters);
    if (loc.error != null) {
      setState(() => _isClaiming = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.error!), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final deviceId = await ApiService.getDeviceInstallId();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await ApiService.claimAttendance(
      token: auth.currentUser!.token,
      sessionId: _activeSession!.sessionId,
      latitude: loc.latitude,
      longitude: loc.longitude,
      accuracyMeters: loc.accuracyMeters,
      capturedAt: loc.capturedAt,
      deviceInstallId: deviceId,
    );
  }

  void _showProfileModal() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1520),
        title: const Text('Student Profile', style: TextStyle(color: Color(0xFF00E6FF), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${auth.user?.email ?? "N/A"}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Registration No: ${auth.user?.registrationNo ?? "N/A"}', style: const TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Department: Software Engineering', style: TextStyle(color: Color(0xFF94A3B8))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1520),
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.location_on, color: Color(0xFF00E6FF)),
            SizedBox(width: 8),
            Text(
              'SWE-Attendance (Student)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        leading: _selectedClass != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF00E6FF)),
                onPressed: () => setState(() => _selectedClass = null),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00E6FF)),
            onPressed: () {
              if (_selectedClass != null) {
                _loadClassDetail(_selectedClass!);
              } else {
                _loadEnrolledClasses();
              }
            },
          ),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF00E6FF)),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: _isLoadingClasses
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E6FF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  // Student Info Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1520),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF213042)),
                    ),
                    if (item.credits != null)
                      Text('${item.credits} Credits', style: const TextStyle(color: Color(0xFF00E6FF), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(item.subjectName ?? item.subjectCode, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Teacher: Faculty', style: const TextStyle(color: Color(0xFF00E6FF), fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${item.subjectCode} • ${item.credits ?? 3.0} Credits', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                const Divider(color: Color(0xFF213042), height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.department, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF00E6FF).withOpacity(0.2),
                          child: const Icon(Icons.badge, color: Color(0xFF00E6FF)),
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
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

                  // Class Selector Dropdown
                  if (_classes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1520),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF213042)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ClassModel>(
                          value: _selectedClass,
                          dropdownColor: const Color(0xFF0D1520),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00E6FF)),
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
                        border: Border.all(color: const Color(0xFF00E6FF)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E6FF).withOpacity(0.3),
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
                        color: const Color(0xFF0D1520),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF213042)),
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
                          color: const Color(0xFF162232),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_myHistory.length} Sessions',
                          style: const TextStyle(color: Color(0xFF00E6FF), fontSize: 12, fontWeight: FontWeight.bold),
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
                        color: const Color(0xFF0D1520),
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
                            color: const Color(0xFF0D1520),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF213042)),
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
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0D1520), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF213042))),
                  child: Column(
                    children: [
                      const Text('ATTENDED', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                      const SizedBox(height: 4),
                      Text('${_myRecords.length}', style: const TextStyle(color: Color(0xFF00FF88), fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('Attendance Log', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          _myRecords.isEmpty
              ? const Text('No attendance records logged yet.', style: TextStyle(color: Color(0xFF94A3B8)))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _myRecords.length,
                  itemBuilder: (ctx, idx) {
                    final r = _myRecords[idx];
                    final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(r.scannedAt.toLocal());
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF0D1520), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF213042))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Text(time, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF00FF88).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                            child: const Text('YES', style: TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

