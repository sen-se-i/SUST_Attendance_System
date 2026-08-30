import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/class_model.dart';
import '../data/subject_catalog.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
          'ADMIN CONSOLE',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5),
        ),
        actions: [

          InkWell(
            onTap: () => auth.logout(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF220000),
                border: Border.all(color: Colors.redAccent),
              ),
              child: const Text(
                'LOGOUT',
                style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                    child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentUser?.email ?? 'admin@sust.edu',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'SYSTEM CONTROL & MANAGEMENT',
                          style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'ADMINISTRATION MODULES',
              style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),

            _buildMenuTile(
              context: context,
              number: '01',
              title: 'VIEW & MANAGE ALL CLASSES',
              subtitle: 'Monitor active classroom sessions, student count & archive completed classes.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminClassesPage()),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildMenuTile(
              context: context,
              number: '02',
              title: 'CREATE STUDENT (AUTO-ENROLL)',
              subtitle: 'Input Reg No. Department & session are auto-parsed and auto-enrolled in running classes.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminCreateStudentPage()),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildMenuTile(
              context: context,
              number: '03',
              title: 'CREATE TEACHER',
              subtitle: 'Register new faculty member and assign their primary academic department.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminCreateTeacherPage()),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildMenuTile(
              context: context,
              number: '04',
              title: 'CREATE CLASS & ASSIGN FACULTY',
              subtitle: 'Create course for department & session. Assign teacher from ANY department. Auto-enrolls all students.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminCreateClassPage()),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildMenuTile(
              context: context,
              number: '05',
              title: 'PASSWORD OVERRIDE',
              subtitle: 'Admin override tool to update password for any Student (Reg No) or Teacher (Email).',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPasswordOverridePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required String number,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                border: Border.all(color: const Color(0xFF444444)),
              ),
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border.all(color: Colors.white),
              ),
              child: const Text(
                'OPEN',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminClassesPage extends StatefulWidget {
  const AdminClassesPage({Key? key}) : super(key: key);

  @override
  State<AdminClassesPage> createState() => _AdminClassesPageState();
}

class _AdminClassesPageState extends State<AdminClassesPage> {
  List<ClassModel> _allClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllClasses();
  }

  Future<void> _loadAllClasses() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.listAllClassesAdmin(auth.token);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.isSuccess && res.data != null) {
          _allClasses = res.data!;
        }
      });
    }
  }

  Future<void> _handleEndClass(String classId, String subjectCode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Color(0xFF444444))),
        title: const Text('END CLASS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        content: Text('Are you sure you want to end and archive class $subjectCode? It will be hidden from teacher & student screens.', style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('END CLASS', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final res = await ApiService.endClassAdmin(auth.token, classId);
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Class archived successfully'),
            backgroundColor: Color(0xFF222222),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
        _loadAllClasses();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leadingWidth: 80,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border.all(color: const Color(0xFF444444)),
            ),
            child: const Text('BACK', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ),
        title: const Text('ALL CLASSES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2)),
        actions: [
          InkWell(
            onTap: _loadAllClasses,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                border: Border.all(color: const Color(0xFF444444)),
              ),
              child: const Text('RELOAD', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : (_allClasses.isEmpty
              ? const Center(
                  child: Text('No classes found in the system.', style: TextStyle(color: Color(0xFF888888))),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allClasses.length,
                  itemBuilder: (context, index) {
                    final item = _allClasses[index];
                    final isEnded = (item.status?.toUpperCase() == 'ENDED');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D),
                        border: Border.all(color: isEnded ? const Color(0xFF222222) : const Color(0xFF333333)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isEnded ? const Color(0xFF222222) : const Color(0xFF1A1A1A),
                                  border: Border.all(color: isEnded ? Colors.redAccent : Colors.white),
                                ),
                                child: Text(
                                  isEnded ? 'STATUS: ENDED' : 'STATUS: ACTIVE',
                                  style: TextStyle(
                                    color: isEnded ? Colors.redAccent : Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text('CODE: ${item.code}', textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.subjectName ?? item.subjectCode,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.subjectCode} • ${item.department} • ${item.academicSession} (${item.semester ?? "N/A"})',
                            style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                          ),
                          const Divider(color: Color(0xFF2A2A2A), height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Teacher: ${item.teacherName ?? "Assigned"}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!isEnded)
                                InkWell(
                                  onTap: () => _handleEndClass(item.id, item.subjectCode),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A0000),
                                      border: Border.all(color: Colors.redAccent),
                                    ),
                                    child: const Text('END CLASS', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                  ),
                                )
                              else
                                const Text('ARCHIVED', style: TextStyle(color: Color(0xFF666666), fontSize: 11, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                )),
    );
  }
}

class AdminCreateStudentPage extends StatefulWidget {
  const AdminCreateStudentPage({Key? key}) : super(key: key);

  @override
  State<AdminCreateStudentPage> createState() => _AdminCreateStudentPageState();
}

class _AdminCreateStudentPageState extends State<AdminCreateStudentPage> {
  final _studentRegController = TextEditingController();
  final _studentPassController = TextEditingController();
  String _calculatedSession = '2023-24';
  String _calculatedDept = 'Software Engineering';
  bool _isCreatingStudent = false;

  void _onStudentRegChanged(String val) {
    final clean = val.trim();
    String sess = '2023-24';
    if (clean.length >= 4) {
      try {
        int year = int.parse(clean.substring(0, 4));
        int next = (year + 1) % 100;
        sess = '$year-${next.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    String dept = 'Software Engineering';
    if (clean.length >= 7) {
      String code = clean.substring(4, 7);
      if (code == '831') {
        dept = 'Software Engineering';
      } else if (code == '331') {
        dept = 'Computer Science and Engineering';
      } else if (code == '332') {
        dept = 'Electrical and Electronic Engineering';
      } else if (code == '134') {
        dept = 'Civil and Environmental Engineering';
      } else if (code == '334') {
        dept = 'Chemical Engineering and Polymer Science';
      } else if (code == '333') {
        dept = 'Industrial and Production Engineering';
      }
    }

    setState(() {
      _calculatedSession = sess;
      _calculatedDept = dept;
      if (_studentPassController.text.isEmpty || _studentPassController.text == clean.substring(0, clean.length > 1 ? clean.length - 1 : 0)) {
        _studentPassController.text = clean;
      }
    });
  }

  Future<void> _handleCreateStudent() async {
    final reg = _studentRegController.text.trim();
    final pass = _studentPassController.text.trim();
    if (reg.isEmpty || pass.isEmpty) {
      _showToast('Please enter registration number and password');
      return;
    }

    setState(() => _isCreatingStudent = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.createStudentAdmin(
      token: auth.token,
      registrationNo: reg,
      password: pass,
    );
    setState(() => _isCreatingStudent = false);

    if (res.isSuccess) {
      _showToast('Student $reg created & auto-enrolled in running classes');
      _studentRegController.clear();
      _studentPassController.clear();
    } else {
      _showToast(res.message ?? 'Failed to create student', isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leadingWidth: 80,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border.all(color: const Color(0xFF444444)),
            ),
            child: const Text('BACK', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ),
        title: const Text('CREATE STUDENT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CREATE NEW STUDENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
              const SizedBox(height: 6),
              const Text('No email required. Department, Session & Class auto-enrollment are calculated automatically from Registration Number.', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const SizedBox(height: 24),

              const Text('STUDENT REGISTRATION NUMBER', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              TextField(
                controller: _studentRegController,
                onChanged: _onStudentRegChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'e.g. 2023831018',
                  hintStyle: TextStyle(color: Color(0xFF555555)),
                  filled: true,
                  fillColor: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 16),

              const Text('INITIAL PASSWORD (DEFAULT = REGISTRATION NO)', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              TextField(
                controller: _studentPassController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Color(0xFF555555)),
                  filled: true,
                  fillColor: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AUTO-PARSED INFORMATION:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Academic Session:', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(_calculatedSession, textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Department:', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(_calculatedDept, textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Auto-Enrollment:', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text('ACTIVE (All running classes)', textAlign: TextAlign.end, style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCreatingStudent ? null : _handleCreateStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: _isCreatingStudent
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('CREATE STUDENT & AUTO-ENROLL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminCreateTeacherPage extends StatefulWidget {
  const AdminCreateTeacherPage({Key? key}) : super(key: key);

  @override
  State<AdminCreateTeacherPage> createState() => _AdminCreateTeacherPageState();
}

class _AdminCreateTeacherPageState extends State<AdminCreateTeacherPage> {
  final _teacherEmailController = TextEditingController();
  final _teacherPassController = TextEditingController();
  String _teacherDept = 'Software Engineering';
  bool _isCreatingTeacher = false;

  Future<void> _handleCreateTeacher() async {
    final email = _teacherEmailController.text.trim();
    final pass = _teacherPassController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _showToast('Please enter faculty email and password');
      return;
    }

    setState(() => _isCreatingTeacher = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.createTeacherAdmin(
      token: auth.token,
      email: email,
      password: pass,
      department: _teacherDept,
    );
    setState(() => _isCreatingTeacher = false);

    if (res.isSuccess) {
      _showToast('Teacher $email created under $_teacherDept');
      _teacherEmailController.clear();
      _teacherPassController.clear();
    } else {
      _showToast(res.message ?? 'Failed to create teacher', isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leadingWidth: 80,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border.all(color: const Color(0xFF444444)),
            ),
            child: const Text('BACK', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ),
        title: const Text('CREATE TEACHER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CREATE NEW TEACHER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
              const SizedBox(height: 6),
              const Text('Register a faculty member under their assigned department.', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const SizedBox(height: 24),

              const Text('FACULTY EMAIL ADDRESS', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              TextField(
                controller: _teacherEmailController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'teacher@sust.edu',
                  hintStyle: TextStyle(color: Color(0xFF555555)),
                  filled: true,
                  fillColor: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 16),

              const Text('PASSWORD', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              TextField(
                controller: _teacherPassController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: Color(0xFF555555)),
                  filled: true,
                  fillColor: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 16),

              const Text('ASSIGNED DEPARTMENT', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: Colors.black, border: Border.all(color: const Color(0xFF333333))),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _teacherDept,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF141414),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: SubjectCatalog.departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _teacherDept = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCreatingTeacher ? null : _handleCreateTeacher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: _isCreatingTeacher
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('CREATE TEACHER ACCOUNT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminCreateClassPage extends StatefulWidget {
  const AdminCreateClassPage({Key? key}) : super(key: key);

  @override
  State<AdminCreateClassPage> createState() => _AdminCreateClassPageState();
}

class _AdminCreateClassPageState extends State<AdminCreateClassPage> {

  String _classDept = 'Software Engineering';
  String _classSession = '2023-24';
  String _classSemester = SubjectCatalog.semesters.first;
  String _classSubjectCode = '';
  String _classSubjectName = '';
  double _classCredits = 3.0;

  String _teacherFilterDept = 'All Departments';
  String? _selectedTeacherId;
  List<Map<String, dynamic>> _availableTeachers = [];
  bool _isLoadingTeachers = false;
  bool _isCreatingClass = false;

  @override
  void initState() {
    super.initState();
    _updateClassSubjects();
    _loadTeachersForDepartment();
  }

  void _updateClassSubjects() {
    final subs = SubjectCatalog.getSubjects(_classDept, _classSemester);
    if (subs.isNotEmpty) {
      _classSubjectCode = subs.first.code;
      _classSubjectName = subs.first.name;
      _classCredits = subs.first.credits;
    } else {
      _classSubjectCode = '';
      _classSubjectName = '';
      _classCredits = 3.0;
    }
  }

  Future<void> _loadTeachersForDepartment() async {
    setState(() => _isLoadingTeachers = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.listTeachersAdmin(
      auth.token,
      department: _teacherFilterDept == 'All Departments' ? null : _teacherFilterDept,
    );
    if (mounted) {
      setState(() {
        _isLoadingTeachers = false;
        if (res.isSuccess && res.data != null) {
          _availableTeachers = res.data!;
          if (_availableTeachers.isNotEmpty) {
            _selectedTeacherId = _availableTeachers.first['id']?.toString();
          } else {
            _selectedTeacherId = null;
          }
        }
      });
    }
  }

  Future<void> _handleCreateClass() async {
    if (_classSubjectCode.isEmpty) {
      _showToast('Please select a subject');
      return;
    }
    if (_selectedTeacherId == null || _selectedTeacherId!.isEmpty) {
      _showToast('Please select an assigned teacher');
      return;
    }

    setState(() => _isCreatingClass = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.createClassAdmin(
      token: auth.token,
      department: _classDept,
      academicSession: _classSession.trim(),
      semester: _classSemester,
      subjectCode: _classSubjectCode,
      subjectName: _classSubjectName,
      credits: _classCredits,
      teacherId: _selectedTeacherId!,
    );
    setState(() => _isCreatingClass = false);

    if (res.isSuccess) {
      _showToast('Class created & all $_classDept ($_classSession) students auto-enrolled');
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      _showToast(res.message ?? 'Failed to create class', isError: true);
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

  @override
  Widget build(BuildContext context) {
    final subjects = SubjectCatalog.getSubjects(_classDept, _classSemester);
    final teacherDeptOptions = ['All Departments', ...SubjectCatalog.departments];

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leadingWidth: 80,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border.all(color: const Color(0xFF444444)),
            ),
            child: const Text('BACK', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ),
        title: const Text('CREATE CLASS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('COURSE & FACULTY ASSIGNMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
              const SizedBox(height: 6),
              const Text('All students in the course department & session will be auto-enrolled. You can assign any faculty member from any department.', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const SizedBox(height: 24),

              const Text('1. COURSE DETAILS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              const SizedBox(height: 10),

              const Text('STUDENT COURSE DEPARTMENT', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: Colors.black, border: Border.all(color: const Color(0xFF333333))),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _classDept,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF141414),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: SubjectCatalog.departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _classDept = val;
                          _updateClassSubjects();
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text('ACADEMIC SESSION (YYYY-YY)', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              TextField(
                controller: TextEditingController(text: _classSession)..selection = TextSelection.collapsed(offset: _classSession.length),
                onChanged: (v) => _classSession = v,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: '2023-24',
                  filled: true,
                  fillColor: Colors.black,
                ),
              ),
              const SizedBox(height: 14),

              const Text('SEMESTER', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: Colors.black, border: Border.all(color: const Color(0xFF333333))),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _classSemester,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF141414),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: SubjectCatalog.semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _classSemester = val;
                          _updateClassSubjects();
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text('SUBJECT', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              if (subjects.isEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF1A1A1A), border: Border.all(color: const Color(0xFF444444))),
                  child: const Text("Subjects for this department hasn't been configured in catalog.", style: TextStyle(color: Colors.white70, fontSize: 11)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: Colors.black, border: Border.all(color: const Color(0xFF333333))),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _classSubjectCode.isNotEmpty ? _classSubjectCode : subjects.first.code,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF141414),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: subjects.map((sub) => DropdownMenuItem(value: sub.code, child: Text('${sub.code} - ${sub.name} (${sub.credits} cr)'))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final found = subjects.firstWhere((element) => element.code == val);
                          setState(() {
                            _classSubjectCode = found.code;
                            _classSubjectName = found.name;
                            _classCredits = found.credits;
                          });
                        }
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFF2A2A2A), height: 1),
              const SizedBox(height: 20),

              const Text('2. ASSIGN FACULTY (ANY DEPARTMENT)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              const SizedBox(height: 10),

              const Text('FILTER TEACHER BY DEPARTMENT', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: Colors.black, border: Border.all(color: const Color(0xFF333333))),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _teacherFilterDept,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF141414),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: teacherDeptOptions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _teacherFilterDept = val;
                        });
                        _loadTeachersForDepartment();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text('SELECT TEACHER', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              if (_isLoadingTeachers)
                const LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.black)
              else if (_availableTeachers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF1A1A1A), border: Border.all(color: Colors.redAccent)),
                  child: const Text('No faculty found in selected department filter. Create teacher in "03. CREATE TEACHER" module.', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: Colors.black, border: Border.all(color: const Color(0xFF333333))),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTeacherId,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF141414),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: _availableTeachers.map((t) {
                        return DropdownMenuItem<String>(
                          value: t['id']?.toString(),
                          child: Text('${t['email']} [${t['department'] ?? "Faculty"}]'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTeacherId = val);
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCreatingClass ? null : _handleCreateClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: _isCreatingClass
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('CREATE CLASS & AUTO-ENROLL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminPasswordOverridePage extends StatefulWidget {
  const AdminPasswordOverridePage({Key? key}) : super(key: key);

  @override
  State<AdminPasswordOverridePage> createState() => _AdminPasswordOverridePageState();
}

class _AdminPasswordOverridePageState extends State<AdminPasswordOverridePage> {
  final _overrideIdentifierController = TextEditingController();
  final _overridePasswordController = TextEditingController();
  bool _isOverridingPassword = false;

  Future<void> _handlePasswordOverride() async {
    final id = _overrideIdentifierController.text.trim();
    final pass = _overridePasswordController.text.trim();
    if (id.isEmpty || pass.isEmpty) {
      _showToast('Enter student Reg No / teacher Email and new password');
      return;
    }

    setState(() => _isOverridingPassword = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.adminResetPassword(auth.token, id, pass);
    setState(() => _isOverridingPassword = false);

    if (res.isSuccess) {
      _showToast('Password updated for $id');
      _overrideIdentifierController.clear();
      _overridePasswordController.clear();
    } else {
      _showToast(res.message ?? 'Failed to reset password', isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leadingWidth: 80,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border.all(color: const Color(0xFF444444)),
            ),
            child: const Text('BACK', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ),
        title: const Text('PASSWORD OVERRIDE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ADMIN PASSWORD OVERRIDE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
              const SizedBox(height: 6),
              const Text('Super-admin override for any Student (by Registration Number) or Teacher (by Email). Regular users cannot reset passwords themselves.', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const SizedBox(height: 24),

              const Text('STUDENT REG NO OR TEACHER EMAIL', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              TextField(
                controller: _overrideIdentifierController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'e.g. 2023831001 or teacher@sust.edu',
                  hintStyle: TextStyle(color: Color(0xFF555555)),
                  filled: true,
                  fillColor: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 16),

              const Text('NEW PASSWORD', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              TextField(
                controller: _overridePasswordController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'New password',
                  hintStyle: TextStyle(color: Color(0xFF555555)),
                  filled: true,
                  fillColor: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isOverridingPassword ? null : _handlePasswordOverride,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: _isOverridingPassword
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('OVERRIDE & SAVE PASSWORD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
