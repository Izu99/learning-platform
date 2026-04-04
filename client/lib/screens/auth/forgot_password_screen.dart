import 'package:flutter/material.dart';
import '../../widgets/edu_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── App Bar ──
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_rounded,
                        size: 20, color: Color(0xFF1E293B)),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text('EduLearn',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B))),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: 48),

              // ── Icon ──
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.lock_reset_outlined,
                      size: 40, color: Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(height: 24),

              const Center(
                child: Text('Forgot Password?',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A))),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  "No worries! Enter your email and we'll\nsend you a reset link.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 36),

              if (!_sent) ...[
                LabeledField(
                  label: 'Email Address',
                  field: EduTextField(
                    hint: 'example@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                  ),
                ),
                const SizedBox(height: 28),
                EduPrimaryButton(
                  label: 'Send Reset Link',
                  onPressed: () => setState(() => _sent = true),
                ),
              ] else ...[
                // ── Success State ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.check_circle_outline_rounded,
                          color: Color(0xFF16A34A), size: 40),
                      SizedBox(height: 12),
                      Text('Email Sent!',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D))),
                      SizedBox(height: 4),
                      Text(
                        'Check your inbox for the reset link.\nMake sure to check your spam folder too.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                EduPrimaryButton(
                  label: 'Back to Login',
                  onPressed: () => Navigator.pop(context),
                ),
              ],

              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('← Back to Login',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
