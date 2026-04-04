import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../widgets/edu_widgets.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../core/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';
import '../dashboard/teacher_setup_screen.dart';

class RegisterStep2Screen extends StatefulWidget {
  final String selectedRole;

  const RegisterStep2Screen({super.key, required this.selectedRole});

  @override
  State<RegisterStep2Screen> createState() => _RegisterStep2ScreenState();
}

class _RegisterStep2ScreenState extends State<RegisterStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = false;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, title: const Text('Complete Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgress(),
                const SizedBox(height: 40),
                _buildRoleBadge(),
                const SizedBox(height: 24),
                Text('Tell us about yourself', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28)),
                const SizedBox(height: 8),
                const Text('Enter your details to finalize your account.', style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 40),
                _buildForm(),
                const SizedBox(height: 32),
                _buildTermsCheckbox(),
                const SizedBox(height: 40),
                _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : EduPrimaryButton(
                      label: 'Create Account',
                      onPressed: _handleCreateAccount,
                    ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('STEP 2 OF 2', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800)),
            const Text('100%', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: 1.0,
            minHeight: 8,
            backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryTeal),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal, size: 16),
          const SizedBox(width: 8),
          Text(
            'Joining as ${widget.selectedRole}',
            style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        EduTextField(
          label: 'Full Name',
          hint: 'Enter your full name',
          icon: Icons.person_outline_rounded,
          controller: _nameController,
          validator: (value) => (value == null || value.isEmpty) ? 'Name is required' : null,
        ),
        const SizedBox(height: 20),
        EduTextField(
          label: 'Email Address',
          hint: 'Enter your email',
          icon: Icons.alternate_email_rounded,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Email is required';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 20),
        EduTextField(
          label: 'Phone Number',
          hint: 'e.g. +94 77 123 4567',
          icon: Icons.phone_android_rounded,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Phone number is required';
            return null;
          },
        ),
        const SizedBox(height: 20),
        EduTextField(
          label: 'Password',
          hint: 'Create a password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          controller: _passwordController,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Password is required';
            if (value.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 20),
        EduTextField(
          label: 'Confirm Password',
          hint: 'Re-enter password',
          icon: Icons.lock_clock_outlined,
          isPassword: true,
          controller: _confirmPasswordController,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please confirm password';
            if (value != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (val) => setState(() => _agreedToTerms = val!),
          activeColor: AppTheme.primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: 'I agree to the ',
              style: Theme.of(context).textTheme.bodySmall,
              children: const [
                TextSpan(text: 'Terms of Service', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                TextSpan(text: ' and '),
                TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to the terms')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService().post('/auth/register', {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'password': _passwordController.text,
        'role': widget.selectedRole,
      });

      if (response.containsKey('token')) {
        final userData = User.fromJson(response['user']);
        final token = response['token'];
        
        if (mounted) {
          // IMPORTANT: Set token and user context immediately
          Provider.of<AuthProvider>(context, listen: false).login(userData, token);
          
          if (widget.selectedRole == 'Teacher') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const TeacherSetupScreen()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(response['message'] ?? 'Registration failed'),
            backgroundColor: Colors.redAccent,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Connection error. Check if your server is reachable at ${AppConstants.baseUrl}'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
