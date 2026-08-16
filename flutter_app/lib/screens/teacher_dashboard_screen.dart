import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/class_model.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../data/subject_catalog.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({Key? key}) : super(key: key);

  @override:
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  List<ClassModel> _classes = [];
  bool _isLoading = false;
  ClassModel? _selectedClass;

  List<AttendanceRecordModel> _classRecords = [];
  Map<String, List<AttendanceRecordModel>> _sessionGroups = {};

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.getClasses(auth.token, true);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.isSuccess && res.data != null) {
          _classes = res.data!;
        }
      });
    }
  }

  Future<void> _loadClassDetails(ClassModel item) async {
    setState(() {
      _selectedClass = item;
      _isLoading = true;
    });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.getClassHistory(auth.token, item.id);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.isSuccess && res.data != null) {
          _classRecords = res.data!;

          _sessionGroups = {};
          for (var r in _classRecords) {
            _sessionGroups.putIfAbsent(r.sessionId, () => []).add(r);
          }
        }
      });
    }
  }

  void _openCreateClassDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CreateClassDialog(
        existingClasses: _classes,
        onCreated: (newClass) {
          _loadClasses();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Class Created! Join Code: ${newClass.code}'),
              backgroundColor: const Color(0xFF00FF88),
            ),
          );
        },
      ),
    );
  }

  void _openStudentControlDialog(String registrationNo) {
    showDialog(
      context: context,
      builder: (ctx) => _StudentControlDialog(
        classId: _selectedClass!.id,
        registrationNo: registrationNo,
        allRecords: _classRecords.where((r) => r.registrationNo == registrationNo).toList(),
        onRefresh: () {
          if (_selectedClass != null) _loadClassDetails(_selectedClass!);
        },
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
          _selectedClass == null ? 'Teacher Dashboard' : (_selectedClass!.subjectName ?? _selectedClass!.subjectCode),
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
                _loadClassDetails(_selectedClass!);
              } else {
                _loadClasses();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E6FF)))
          : _selectedClass == null
              ? _buildActiveClassesGrid()
              : _buildClassDetailView(),
      floatingActionButton: _selectedClass == null
          ? FloatingActionButton.extended(
              onPressed: _openCreateClassDialog,
              backgroundColor: const Color(0xFF00E6FF),
              icon: const Icon(Icons.add, color: Colors.black, size: 26),
              label: const Text(
                '+ CREATE CLASS',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            )
          : null,
    );
  }

  Widget _buildActiveClassesGrid() {
    if (_classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book, size: 64, color: Color(0xFF213042)),
            const SizedBox(height: 16),
            const Text('No Active Classes Created', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tap "+ CREATE CLASS" below to add your first course.', style: TextStyle(color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Classes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Select a class to manage sessions & attendance.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _classes.length,
              itemBuilder: (context, index) {
                final item = _classes[index];
                return GestureDetector(
                  onTap: () => _loadClassDetails(item),
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
                        Text(
                          item.subjectName ?? item.subjectCode,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.subjectCode} • ${item.academicSession} • ${item.semester ?? "Semester N/A"}',
                          style: const TextStyle(color: Color(0xFF00E6FF), fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const Divider(color: Color(0xFF213042), height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.department, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            const Row(
                              children: [
                                Text('Open Details', style: TextStyle(color: Color(0xFF00E6FF), fontWeight: FontWeight.bold, fontSize: 13)),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDetailView() {
    final students = _classRecords.map((r) => r.registrationNo).toSet().toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1520),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00E6FF).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedClass!.subjectName ?? _selectedClass!.subjectCode, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${_selectedClass!.department} • ${_selectedClass!.academicSession}', style: const TextStyle(color: Color(0xFF00E6FF), fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                      child: Text('JOIN CODE: ${_selectedClass!.code}', style: const TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Class Session History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _sessionGroups.isEmpty
              ? const Text('No attendance sessions taken yet.', style: TextStyle(color: Color(0xFF94A3B8)))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sessionGroups.keys.length,
                  itemBuilder: (ctx, idx) {
                    final sId = _sessionGroups.keys.elementAt(idx);
                    final recs = _sessionGroups[sId]!;
                    final time = recs.isNotEmpty ? DateFormat('yyyy-MM-dd HH:mm').format(recs.first.scannedAt.toLocal()) : 'N/A';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1520),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF213042)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Color(0xFF00E6FF), size: 16),
                              const SizedBox(width: 8),
                              Text(time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Text('${recs.length} Verified', style: const TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
          const SizedBox(height: 24),

          const Text('Class Roster & Controls', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          students.isEmpty
              ? const Text('No student records found.', style: TextStyle(color: Color(0xFF94A3B8)))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (ctx, idx) {
                    final regNo = students[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1520),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF213042)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(regNo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF213042),
                              foregroundColor: const Color(0xFF00E6FF),
                            ),
                            onPressed: () => _openStudentControlDialog(regNo),
                            child: const Text('Manage Student'),
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

class _CreateClassDialog extends StatefulWidget {
  final List<ClassModel> existingClasses;
  final Function(ClassModel) onCreated;

  const _CreateClassDialog({Key? key, required this.existingClasses, required this.onCreated}) : super(key: key);

  @override:
  State<_CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<_CreateClassDialog> {
  String _department = SubjectCatalog.departments.first;
  String _academicSession = '2023-24';
  String _semester = SubjectCatalog.semesters.first;
  String _subjectCode = '';
  String _subjectName = '';
  double _credits = 3.0;

  String? _sessionError;
  String? _duplicateError;
  bool _isBusy = false;
  List<SubjectItem> _availableSubjects = [];

  @override
  void initState() {
    super.initState();
    _updateSubjects();
  }

  void _updateSubjects() {
    _availableSubjects = SubjectCatalog.getSubjects(_department, _semester);
    if (_availableSubjects.isNotEmpty) {
      _subjectCode = _availableSubjects.first.code;
      _subjectName = _availableSubjects.first.name;
      _credits = _availableSubjects.first.credits;
    } else {
      _subjectCode = '';
      _subjectName = '';
      _credits = 3.0;
    }
    _checkDuplicate();
  }

  void _handleSessionChange(String val) {
    _academicSession = val;
    final regex = RegExp(r'^\d{4}-\d{2}$');
    if (val.isNotEmpty && !regex.hasMatch(val)) {
      _sessionError = 'Format must be YYYY-YY (e.g. 2023-24)';
    } else {
      _sessionError = null;
    }
    _checkDuplicate();
    setState(() {});
  }

  void _checkDuplicate() {
    if (_department != 'Software Engineering') {
      _duplicateError = null;
      return;
    }
    final isDup = widget.existingClasses.any(
      (c) => c.academicSession == _academicSession && c.semester == _semester && c.subjectCode == _subjectCode,
    );
    if (isDup) {
      _duplicateError = 'Class for $_subjectCode in $_academicSession ($_semester) already exists!';
    } else {
      _duplicateError = null;
    }
  }

  Future<void> _submit() async {
    if (_sessionError != null || _duplicateError != null) return;
    setState(() => _isBusy = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.createClass(
      token: auth.token,
      department: _department,
      academicSession: _academicSession,
      semester: _semester,
      subjectCode: _subjectCode,
      subjectName: _subjectName,
      credits: _credits,
    );
    setState(() => _isBusy = false);

    if (res.isSuccess && res.data != null) {
      Navigator.of(context).pop();
      widget.onCreated(res.data!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'Failed to create class')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0D1520),
      title: const Text('Create New Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text('Department', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            DropdownButton<String>(
              value: _department,
              isExpanded: true,
              dropdownColor: const Color(0xFF0D1520),
              style: const TextStyle(color: Colors.white),
              items: SubjectCatalog.departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _department = val;
                    _updateSubjects();
                  });
                }
              },
            ),
            const SizedBox(height: 12),

            const Text('Academic Session (Format: YYYY-YY)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            TextField(
              controller: TextEditingController(text: _academicSession)..selection = TextSelection.collapsed(offset: _academicSession.length),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '2023-24',
                hintStyle: const TextStyle(color: Colors.white30),
                errorText: _sessionError,
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _duplicateError != null ? Colors.red : const Color(0xFF213042))),
              ),
              onChanged: _handleSessionChange,
            ),
            const SizedBox(height: 12),

            const Text('Semester', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            DropdownButton<String>(
              value: _semester,
              isExpanded: true,
              dropdownColor: const Color(0xFF0D1520),
              style: const TextStyle(color: Colors.white),
              items: SubjectCatalog.semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _semester = val;
                    _updateSubjects();
                  });
                }
              },
            ),
            const SizedBox(height: 12),

            const Text('Subject', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            if (_department != 'Software Engineering')
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), border: Border.all(color: Colors.amber)),
                child: const Text("subjects for this department hasn't been updated", style: TextStyle(color: Colors.amber, fontSize: 12)),
              )
            else
              DropdownButton<String>(
                value: _subjectCode,
                isExpanded: true,
                dropdownColor: const Color(0xFF0D1520),
                style: const TextStyle(color: Colors.white),
                items: _availableSubjects.map((sub) => DropdownMenuItem(value: sub.code, child: Text(sub.name))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final found = _availableSubjects.firstWhere((element) => element.code == val);
                    setState(() {
                      _subjectCode = found.code;
                      _subjectName = found.name;
                      _credits = found.credits;
                      _checkDuplicate();
                    });
                  }
                },
              ),

            if (_duplicateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_duplicateError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E6FF), foregroundColor: Colors.black),
          onPressed: _isBusy || _sessionError != null || _duplicateError != null || _subjectCode.isEmpty ? null : _submit,
          child: const Text('Create Class', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _StudentControlDialog extends StatefulWidget {
  final String classId;
  final String registrationNo;
  final List<AttendanceRecordModel> allRecords;
  final VoidCallback onRefresh;

  const _StudentControlDialog({
    Key? key,
    required this.classId,
    required this.registrationNo,
    required this.allRecords,
    required this.onRefresh,
  }) : super(key: key);

  @override:
  State<_StudentControlDialog> createState() => _StudentControlDialogState();
}

class _StudentControlDialogState extends State<_StudentControlDialog> {
  bool _showAdvance = false;
  final List<String> _selectedIds = [];
  bool _isBusy = false;

  Future<void> _resetDevice() async {
    setState(() => _isBusy = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await ApiService.resetStudentDevice(auth.token, widget.registrationNo);
    setState(() => _isBusy = false);

    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Device ID reset for ${widget.registrationNo}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'Reset failed')));
    }
  }

  Future<void> _deleteFullHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1520),
        title: const Text('Delete Full History?', style: TextStyle(color: Colors.redAccent)),
        content: Text('Permanently delete all records for ${widget.registrationNo}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isBusy = true);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.deleteStudentClassHistory(auth.token, widget.classId, widget.registrationNo);
      setState(() => _isBusy = false);
      widget.onRefresh();
      Navigator.pop(context);
    }
  }

  Future<void> _deleteSelectedHistory() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1520),
        title: Text('Delete ${_selectedIds.length} Selected Record(s)?', style: const TextStyle(color: Colors.redAccent)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Selected'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isBusy = true);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await ApiService.deleteBatchAttendanceRecords(auth.token, _selectedIds);
      setState(() => _isBusy = false);
      widget.onRefresh();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0D1520),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(widget.registrationNo, style: const TextStyle(color: Color(0xFF00E6FF), fontSize: 24, fontWeight: FontWeight.w900)),

          Text('CLASS ID: ${widget.classId}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF88).withOpacity(0.2), foregroundColor: const Color(0xFF00FF88)),
                    icon: const Icon(Icons.smartphone, size: 16),
                    label: const Text('Reset Device ID'),
                    onPressed: _isBusy ? null : _resetDevice,
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: _showAdvance ? Colors.redAccent : Colors.white),
                    onPressed: () => setState(() => _showAdvance = !_showAdvance),
                    child: Text(_showAdvance ? 'Hide Advance' : 'Advance'),
                  ),
                ],
              ),
              if (_showAdvance) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), border: Border.all(color: Colors.red.withOpacity(0.4)), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: _isBusy ? null : _deleteFullHistory,
                        child: const Text('Delete FULL History'),
                      ),
                      if (_selectedIds.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                          onPressed: _isBusy ? null : _deleteSelectedHistory,
                          child: Text('Delete Selected (${_selectedIds.length})'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerLeft, child: Text('Attendance History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              widget.allRecords.isEmpty
                  ? const Text('No history found.', style: TextStyle(color: Color(0xFF94A3B8)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.allRecords.length,
                      itemBuilder: (ctx, idx) {
                        final item = widget.allRecords[idx];
                        final isSelected = _selectedIds.contains(item.id);
                        return ListTile(
                          dense: true,
                          leading: _showAdvance
                              ? Checkbox(
                                  value: isSelected,
                                  activeColor: Colors.red,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedIds.add(item.id);
                                      } else {
                                        _selectedIds.remove(item.id);
                                      }
                                    });
                                  },
                                )
                              : null,
                          title: Text(DateFormat('yyyy-MM-dd HH:mm').format(item.scannedAt.toLocal()), style: const TextStyle(color: Colors.white)),
                          subtitle: Text('Device: ${item.deviceInstallId.length > 12 ? item.deviceInstallId.substring(0, 12) + "..." : item.deviceInstallId}', style: const TextStyle(color: Color(0xFF94A3B8))),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

