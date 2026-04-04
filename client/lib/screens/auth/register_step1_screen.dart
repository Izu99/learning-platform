import 'package:flutter/material.dart';
import 'package:learning_platform/core/app_theme.dart';
import 'package:learning_platform/widgets/edu_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';
import 'register_step2_screen.dart';

class RegisterStep1Screen extends StatefulWidget {
  const RegisterStep1Screen({super.key});

  @override
  State<RegisterStep1Screen> createState() => _RegisterStep1ScreenState();
}

class _RegisterStep1ScreenState extends State<RegisterStep1Screen> {
  int _selected = 0;

  static const List<_RoleItem> _roles = [
    _RoleItem(Icons.school_rounded, 'Teacher', 'Share your English expertise'),
    _RoleItem(Icons.face_retouching_natural_rounded, 'Student', 'Master the English language'),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppDesignTokens>()!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgress(),
              const SizedBox(height: 48),
              Text('Who are you?', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text('Select your role to personalize your experience.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 40),
              _buildRoleGrid(tokens),
              const SizedBox(height: 48),
              EduPrimaryButton(
                label: 'Continue',
                showArrow: true,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterStep2Screen(
                      selectedRole: _roles[_selected].title,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildLoginLink(),
            ],
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
            Text('STEP 1 OF 2', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800)),
            const Text('50%', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: 0.5,
            minHeight: 8,
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleGrid(AppDesignTokens tokens) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: _roles.length,
      itemBuilder: (_, i) => _RoleCard(
        item: _roles[i],
        selected: _selected == i,
        tokens: tokens,
        onTap: () => setState(() => _selected = i),
      ).animate().fadeIn(delay: (i * 100).ms).scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        child: RichText(
          text: TextSpan(
            text: 'Already have an account? ',
            style: Theme.of(context).textTheme.bodyMedium,
            children: const [
              TextSpan(text: 'Log In', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const _RoleItem(this.icon, this.title, this.subtitle);
}

class _RoleCard extends StatelessWidget {
  final _RoleItem item;
  final bool selected;
  final AppDesignTokens tokens;
  final VoidCallback onTap;

  const _RoleCard({required this.item, required this.selected, required this.tokens, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primaryGreen : AppTheme.textMuted;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppTheme.primaryGreen : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [tokens.softShadow] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryGreen : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: selected ? Colors.white : AppTheme.textSecondary, size: 24),
            ),
            const SizedBox(height: 16),
            Text(item.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: selected ? AppTheme.primaryGreen : AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(item.subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3), maxLines: 2),
          ],
        ),
      ),
    );
  }
}
