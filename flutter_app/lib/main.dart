import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/teacher_dashboard_screen.dart';
import 'screens/student_dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const SweAttendanceApp(),
    ),
  );
}

class SweAttendanceApp extends StatelessWidget {
  const SweAttendanceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SWE Attendance System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFF00E6FF),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E6FF),
          secondary: Color(0xFF00FF88),
          surface: Color(0xFF0D1520),
          background: Color(0xFF000000),
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return const LoginScreen();
          }
          if (auth.isTeacher) {
            return const TeacherDashboardScreen();
          } else {
            return const StudentDashboardScreen();
          }
        },
      ),
    );
  }
}

