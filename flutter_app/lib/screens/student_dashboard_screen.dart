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

  void _openJoinClassDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1520),
        title: const Text('Join New Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter 6-character Class Code:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
              decoration: const InputDecoration(
                hintText: 'e.g. SWE23A',
                hintStyle: TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E6FF))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E6FF), foregroundColor: Colors.black),
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final res = await ApiService.claimAttendance(
                token: auth.token,
                sessionId: '',
                latitude: 0,
                longitude: 0,
                accuracyMeters: 0,
                capturedAt: DateTime.now(),
                deviceInstallId: '',
              );
              Navigator.pop(ctx);
              _loadEnrolledClasses();
            },
            child: const Text('Join Class', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
        title: Text(
          _selectedClass == null ? 'My Enrolled Classes' : (_selectedClass!.subjectName ?? _selectedClass!.subjectCode),
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        leading: _selectedClass != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF00E6FF)),
                onPressed: () => setState(() => _selectedClass = null),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00E6FF)),
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
      endDrawer: Drawer(
        backgroundColor: const Color(0xFF090F17),
        child: SafeArea(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF0D1520)),
                accountName: Text(auth.user?.email.split('@').first ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                accountEmail: Text(auth.user?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: const Color(0xFF00E6FF),
                  child: Text(auth.user?.email.substring(0, 1).toUpperCase() ?? 'S', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF00E6FF)),
                title: const Text('My Profile', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showProfileModal();
                },
              ),
              const Spacer(),
              const Divider(color: Color(0xFF213042)),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  auth.logout();
                },
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E6FF)))
          : _selectedClass == null
              ? _buildEnrolledClassesGrid()
              : _buildClassDetailView(),
      floatingActionButton: _selectedClass == null
          ? FloatingActionButton.extended(
              onPressed: _openJoinClassDialog,
              backgroundColor: const Color(0xFF00FF88),
              icon: const Icon(Icons.add, color: Colors.black, size: 26),
              label: const Text(
                '+ JOIN CLASS',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            )
          : null,
    );
  }

  Widget _buildEnrolledClassesGrid() {
    if (_classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book, size: 64, color: Color(0xFF213042)),
            const SizedBox(height: 16),
            const Text('No Classes Enrolled Yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tap "+ JOIN CLASS" below to join your first course.', style: TextStyle(color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _classes.length,
      itemBuilder: (ctx, idx) {
        final item = _classes[idx];
        return GestureDetector(
          onTap: () => _loadClassDetail(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1520),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF213042)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF88).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00FF88)),
                      ),
                      child: Text('CODE: ${item.code}', style: const TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold, fontSize: 12)),
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
                        Text('View Attendance Log', style: TextStyle(color: Color(0xFF00E6FF), fontWeight: FontWeight.bold, fontSize: 13)),
                        Icon(Icons.chevron_right, color: Color(0xFF00E6FF), size: 18),
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

  Widget _buildClassDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1520),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00E6FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedClass!.subjectName ?? _selectedClass!.subjectCode, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${_selectedClass!.department} • ${_selectedClass!.academicSession}', style: const TextStyle(color: Color(0xFF00E6FF))),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0D1520), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF213042))),
                  child: Column(
                    children: [
                      const Text('TOTAL SESSIONS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                      const SizedBox(height: 4),
                      Text('${_myRecords.length}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
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

