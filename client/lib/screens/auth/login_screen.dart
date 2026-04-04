import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/app_theme.dart';
import 'package:learning_platform/core/auth_provider.dart';
import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/core/constants.dart';
import 'package:learning_platform/models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:learning_platform/screens/dashboard/main_navigation.dart';
import 'package:learning_platform/screens/dashboard/teacher_navigation.dart';
import 'package:learning_platform/screens/admin/admin_dashboard_screen.dart';
import 'register_step1_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Gradient top
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.38,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F4C3A), AppTheme.primaryTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top hero area
                  _buildHero(),
                  // White card
                  _buildFormCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Logo
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 28),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
        const Text('EmuLearn', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.1)),
        if (kDebugMode) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('API: ${AppConstants.baseUrl}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
          ),
        ],
      ]),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Sign in to your account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text('Enter your credentials to continue', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 32),
          // Email field
          _buildFieldLabel('Email Address'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            decoration: _fieldDecoration('Enter your email', Icons.alternate_email_rounded),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Enter a valid email';
              return null;
            },
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 20),
          // Password field
          _buildFieldLabel('Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            decoration: _fieldDecoration('Enter your password', Icons.lock_outline_rounded).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey.shade400, size: 20),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Min. 6 characters';
              return null;
            },
          ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.05),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
              child: const Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryGreen, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 28),
          // Login button
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
              : SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.98, 0.98)),
                ),
          const SizedBox(height: 36),
          // Divider
          Row(children: [
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('OR CONTINUE WITH', style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          ]),
          const SizedBox(height: 24),
          // Social buttons
          Row(children: [
            Expanded(child: _socialBtn('Google', Icons.g_mobiledata_rounded, Colors.red)),
            const SizedBox(width: 14),
            Expanded(child: _socialBtn('Apple', Icons.apple_rounded, Colors.black87)),
          ]).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 32),
          // Sign up link
          Center(
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterStep1Screen())),
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                  children: const [TextSpan(text: 'Sign Up', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w800))],
                ),
              ),
            ),
          ),
        ]),
      ),
    ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.04);
  }

  Widget _buildFieldLabel(String label) => Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.3));

  InputDecoration _fieldDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 16, right: 12),
      child: Icon(icon, size: 20, color: Colors.grey.shade400),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.accentRed)),
    hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w400),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  );

  Widget _socialBtn(String label, IconData icon, Color color) => Container(
    height: 50,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
    ])),
  );

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().post('/auth/login', {
        'email': _emailCtrl.text.trim(),
        'password': _passCtrl.text,
      });
      if (response.containsKey('token') && mounted) {
        final user = User.fromJson(response['user']);
        Provider.of<AuthProvider>(context, listen: false).login(user, response['token']);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
          final role = user.role.toLowerCase();
          if (role == 'admin') return const AdminDashboardScreen();
          if (role == 'teacher') return const TeacherNavigationContainer();
          return const MainNavigationContainer();
        }));
      } else if (mounted) {
        _showError(response['message'] ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      if (mounted) _showError('Connection failed. Is your server running?\n${AppConstants.baseUrl}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 5),
    ));
  }
}
