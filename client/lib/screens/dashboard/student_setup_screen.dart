import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/app_theme.dart';
import 'package:learning_platform/widgets/edu_widgets.dart';
import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/core/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'main_navigation.dart';

class StudentSetupScreen extends StatefulWidget {
  const StudentSetupScreen({super.key});

  @override
  State<StudentSetupScreen> createState() => _StudentSetupScreenState();
}

class _StudentSetupScreenState extends State<StudentSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final List<String> _selectedTopics = [];
  final List<String> _availableTopics = ['Speaking', 'Grammar', 'IELTS', 'Writing', 'Listening', 'Vocabulary', 'Pronunciation'];
  String _selectedLevel = 'Intermediate';

  void _nextPage() {
    if (_currentStep < 1) {
      _pageController.nextPage(duration: 300.ms, curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _handleSave();
    }
  }

  Future<void> _handleSave() async {
    try {
      await ApiService().post('/auth/preferences', {
        'interests': _selectedTopics,
        'level': _selectedLevel,
      });
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).updateUserPreferences(
          interests: _selectedTopics,
          level: _selectedLevel,
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationContainer()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Quick Preferences'),
        leading: _currentStep > 0 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {
          _pageController.previousPage(duration: 300.ms, curve: Curves.easeInOut);
          setState(() => _currentStep--);
        }) : null,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTopicsStep(),
                _buildLevelStep(),
              ],
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STEP ${_currentStep + 1} OF 2', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800)),
              Text('${((_currentStep + 1) / 2 * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 2,
              minHeight: 8,
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What would you like to learn?', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 26)),
          const SizedBox(height: 12),
          Text('Select the topics that interest you most.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 40),
          Wrap(
            spacing: 12,
            runSpacing: 16,
            children: _availableTopics.map((topic) {
              final isSelected = _selectedTopics.contains(topic);
              return FilterChip(
                label: Text(topic),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedTopics.add(topic);
                    } else {
                      _selectedTopics.remove(topic);
                    }
                  });
                },
                selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                checkmarkColor: AppTheme.primaryBlue,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0))),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          _CustomTopicInput(),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _buildLevelStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your English level?', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 26)),
          const SizedBox(height: 12),
          Text('This helps us recommend the best teachers for you.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 40),
          _LevelCard(
            title: 'Beginner',
            subtitle: 'Starting from scratch',
            icon: Icons.eco_rounded,
            isSelected: _selectedLevel == 'Beginner',
            onTap: () => setState(() => _selectedLevel = 'Beginner'),
          ),
          const SizedBox(height: 16),
          _LevelCard(
            title: 'Intermediate',
            subtitle: 'Can hold basic conversations',
            icon: Icons.bolt_rounded,
            isSelected: _selectedLevel == 'Intermediate',
            onTap: () => setState(() => _selectedLevel = 'Intermediate'),
          ),
          const SizedBox(height: 16),
          _LevelCard(
            title: 'Advanced',
            subtitle: 'Fluent and looking for mastery',
            icon: Icons.rocket_launch_rounded,
            isSelected: _selectedLevel == 'Advanced',
            onTap: () => setState(() => _selectedLevel = 'Advanced'),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: EduPrimaryButton(
        label: _currentStep < 1 ? 'Next' : 'Start Learning',
        showArrow: true,
        onPressed: _nextPage,
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelCard({required this.title, required this.subtitle, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ModernCard(
        padding: const EdgeInsets.all(24),
        color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.05) : Colors.white,
        radius: 24,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppTheme.textSecondary, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                    fontSize: 18,
                  )),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue, size: 24),
          ],
        ),
      ),
    );
  }
}

class _CustomTopicInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Add custom topic...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: Icon(Icons.edit_note_rounded, color: AppTheme.textMuted),
        ),
      ),
    );
  }
}
