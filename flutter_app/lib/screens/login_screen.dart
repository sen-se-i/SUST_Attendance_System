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
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Branding
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF38BDF8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF818CF8), Color(0xFF38BDF8)],
                  ).createShader(bounds),
                  child: const Text(
                    'SWE-Attendance',
                    style: TextStyle(
                      fontSize: 30,
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

                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181829),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2D2D44)),
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

                      // Email Field
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF818CF8)),
                          filled: true,
                          fillColor: const Color(0xFF0F0F1A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF818CF8)),
                          filled: true,
                          fillColor: const Color(0xFF0F0F1A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (!_isLogin) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          dropdownColor: const Color(0xFF181829),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Account Role',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF818CF8)),
                            filled: true,
                            fillColor: const Color(0xFF0F0F1A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
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
                              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF818CF8)),
                              filled: true,
                              fillColor: const Color(0xFF0F0F1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],

                      // Quick Demo Account Buttons
                      if (_isLogin) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              backgroundColor: const Color(0xFF25253A),
                              avatar: const Icon(Icons.school, size: 16, color: Color(0xFF38BDF8)),
                              label: const Text('Teacher Demo', style: TextStyle(color: Colors.white, fontSize: 11)),
                              onPressed: () {
                                _emailController.text = 'teacher@example.com';
                                _passwordController.text = 'password';
                              },
                            ),
                            ActionChip(
                              backgroundColor: const Color(0xFF25253A),
                              avatar: const Icon(Icons.person, size: 16, color: Color(0xFF818CF8)),
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

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _isLogin ? 'Sign In' : 'Register Account',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
                            style: const TextStyle(color: Color(0xFF818CF8)),
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
