import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'admin@example.com');
  final _passwordController = TextEditingController(text: 'password');

  void _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final emailOrReg = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (emailOrReg.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter registration no / email and password'),
          backgroundColor: Color(0xFF222222),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
      return;
    }

    final success = await auth.login(emailOrReg, password);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Invalid credentials. Please verify your info.'),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minimalist Square Text Badge Logo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    border: Border.all(color: const Color(0xFFFFFFFF), width: 1.5),
                  ),
                  child: const Text(
                    'SUST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'ATTENDANCE SYSTEM',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'GPS Geofenced Classroom Attendance Portal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 36),

                // Main Login Form - Sharp Square Box
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D0D),
                    border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PORTAL SIGN IN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F1F1F),
                              border: Border.all(color: const Color(0xFF444444)),
                            ),
                            child: const Text(
                              'AUTH',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Email / Reg No Field
                      const Text('EMAIL OR REGISTRATION NUMBER', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'admin@example.com or 2023831001',
                          hintStyle: TextStyle(color: Color(0xFF555555)),
                          filled: true,
                          fillColor: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      const Text('PASSWORD', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: '••••••••',
                          hintStyle: TextStyle(color: Color(0xFF555555)),
                          filled: true,
                          fillColor: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 1-Click Demo Accounts for 3 Distinct Roles - Pure Clean Boxes
                      const Text('1-CLICK DEMO ACCOUNTS:', style: TextStyle(color: Color(0xFF666666), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          Row(
                            children: [
                              // Admin Demo Button
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _emailController.text = 'admin@example.com';
                                      _passwordController.text = 'password';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF161616),
                                      border: Border.all(color: const Color(0xFF444444)),
                                    ),
                                    child: const Text('ADMIN DEMO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Teacher Demo Button
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _emailController.text = 'teacher@example.com';
                                      _passwordController.text = 'password';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF161616),
                                      border: Border.all(color: const Color(0xFF444444)),
                                    ),
                                    child: const Text('TEACHER DEMO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Student Demo Button
                          InkWell(
                            onTap: () {
                              setState(() {
                                _emailController.text = '2023831001';
                                _passwordController.text = '2023831001';
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF161616),
                                border: Border.all(color: const Color(0xFF444444)),
                              ),
                              child: const Text('STUDENT DEMO (2023831001)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Sign In Button - Sharp Square
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFFFF),
                            foregroundColor: const Color(0xFF000000),
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Text(
                                  'SIGN IN',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
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
