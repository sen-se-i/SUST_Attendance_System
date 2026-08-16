import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'teacher@example.com');
  final _passwordController = TextEditingController(text: 'password');
  final _regNoController = TextEditingController();
  bool _isLogin = true;
  String _selectedRole = 'STUDENT';

  void _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all credentials')),
      );
      return;
    }

    bool success;
    if (_isLogin) {
      success = await auth.login(email, password);
    } else {
      success = await auth.register(
        email: email,
        password: password,
        role: _selectedRole,
        registrationNo: _selectedRole == 'STUDENT' ? _regNoController.text.trim() : null,
      );
    }

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Authentication failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D1520),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E6FF).withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00E6FF), Color(0xFF00FF88)],
                  ).createShader(bounds),
                  child: const Text(
                    'SWE Attendance System',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'GPS Geofenced Classroom Attendance System',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 36),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1520),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF213042)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Text(
                        _isLogin ? 'Sign In' : 'Create Account',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF00E6FF)),
                          filled: true,
                          fillColor: const Color(0xFF070B12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF213042)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF213042)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF00E6FF)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00E6FF)),
                          filled: true,
                          fillColor: const Color(0xFF070B12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF213042)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF213042)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF00E6FF)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (!_isLogin) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          dropdownColor: const Color(0xFF0D1520),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Account Role',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF00E6FF)),
                            filled: true,
                            fillColor: const Color(0xFF070B12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF213042)),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'STUDENT', child: Text('Student')),
                            DropdownMenuItem(value: 'ADMIN', child: Text('Teacher / Admin')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRole = val);
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_selectedRole == 'STUDENT') ...[
                          TextField(
                            controller: _regNoController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Registration Number',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF00E6FF)),
                              filled: true,
                              fillColor: const Color(0xFF070B12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF213042)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],

                      if (_isLogin) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              backgroundColor: const Color(0xFF162232),
                              avatar: const Icon(Icons.school, size: 16, color: Color(0xFF00E6FF)),
                              label: const Text('Teacher Demo', style: TextStyle(color: Colors.white, fontSize: 11)),
                              onPressed: () {
                                _emailController.text = 'teacher@example.com';
                                _passwordController.text = 'password';
                              },
                            ),
                            ActionChip(
                              backgroundColor: const Color(0xFF162232),
                              avatar: const Icon(Icons.person, size: 16, color: Color(0xFF00FF88)),
                              label: const Text('Student Demo', style: TextStyle(color: Colors.white, fontSize: 11)),
                              onPressed: () {
                                _emailController.text = 'ch.wixard@student.sust.edu';
                                _passwordController.text = 'password';
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E6FF),
                            foregroundColor: const Color(0xFF030712),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Color(0xFF030712), strokeWidth: 2),
                                )
                              : Text(
                                  _isLogin ? 'Sign In' : 'Register Account',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF030712),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(
                            _isLogin
                                ? "Don't have an account? Register"
                                : 'Already have an account? Sign In',
                            style: const TextStyle(color: Color(0xFF00E6FF)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

