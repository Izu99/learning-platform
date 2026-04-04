import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../widgets/edu_widgets.dart';
import '../../core/api_service.dart';
import '../../models/teacher_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'teacher_navigation.dart';
import '../../widgets/modern_avatar.dart';
import '../../core/auth_provider.dart';
import 'package:provider/provider.dart';

class TeacherSetupScreen extends StatefulWidget {
  const TeacherSetupScreen({super.key});

  @override
  State<TeacherSetupScreen> createState() => _TeacherSetupScreenState();
}

class _TeacherSetupScreenState extends State<TeacherSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form Controllers
  final _bioController = TextEditingController();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceController = TextEditingController();
  
  final List<Qualification> _qualifications = [];
  final List<String> _selectedTopics = [];
  final List<String> _availableTopics = ['Speaking', 'Grammar', 'IELTS', 'Writing', 'Listening', 'Business English'];

  @override
  void dispose() {
    _pageController.dispose();
    _bioController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
    }

    if (_currentStep < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _handleSave();
    }
  }

  Future<void> _handleSave() async {
    try {
      await ApiService().post('/teachers/profile', {
        'userId': Provider.of<AuthProvider>(context, listen: false).currentUser?.id,
        'title': _titleController.text.trim(),
        'bio': _bioController.text.trim(),
        'qualifications': _qualifications.map((q) => q.toJson()).toList(),
        'tags': _selectedTopics,
        'experienceYears': int.tryParse(_experienceController.text) ?? 0,
        'price': double.tryParse(_priceController.text) ?? 35.0,
      });
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherNavigationContainer()));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Setup your profile'),
        leading: _currentStep > 0 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {
          _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          setState(() => _currentStep--);
        }) : null,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBasicInfoStep(),
                  _buildQualificationsStep(),
                  _buildTopicsAndExperienceStep(),
                  _buildPricingAndAvailabilityStep(),
                ],
              ),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    const teal = AppTheme.primaryTeal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STEP ${_currentStep + 1} OF 4', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800)),
              Text('${((_currentStep + 1) / 4 * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: teal)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 4,
              minHeight: 6,
              backgroundColor: teal.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(teal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                ModernAvatar(
                  imageUrl: Provider.of<AuthProvider>(context, listen: false).currentUser?.profileImageUrl,
                  fallbackText: Provider.of<AuthProvider>(context, listen: false).currentUser?.name ?? 'T',
                  radius: 50,
                ),
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const SectionHeader(title: 'Basic Information'),
          const SizedBox(height: 24),
          EduTextField(
            label: 'Professional Title',
            hint: 'e.g. IELTS Coach, Business English Expert', 
            icon: Icons.work_outline_rounded, 
            controller: _titleController,
            validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
          ),
          const SizedBox(height: 24),
          EduTextField(
            label: 'Short Bio',
            hint: 'Tell students about your teaching style', 
            icon: Icons.history_edu_rounded, 
            controller: _bioController,
            validator: (v) => (v == null || v.isEmpty) ? 'Bio is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildQualificationsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Qualifications'),
          const SizedBox(height: 16),
          if (_qualifications.isEmpty)
             const Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('No qualifications added yet.', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ..._qualifications.map((q) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ModernCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.school_rounded, color: AppTheme.primaryGreen),
                  const SizedBox(width: 16),
                  Expanded(child: Text('${q.title} at ${q.institution}', style: const TextStyle(fontWeight: FontWeight.w600))),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () => setState(() => _qualifications.remove(q)),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showAddQualificationDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Qualification'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsAndExperienceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Teaching Topics'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _availableTopics.map((topic) {
              final isSelected = _selectedTopics.contains(topic);
              const teal = AppTheme.primaryTeal;
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
                selectedColor: teal.withOpacity(0.2),
                checkmarkColor: teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          const SectionHeader(title: 'Experience'),
          const SizedBox(height: 24),
          EduTextField(
            label: 'Years of Experience',
            hint: 'How long have you been teaching?', 
            icon: Icons.timeline_rounded, 
            controller: _experienceController,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingAndAvailabilityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Pricing'),
          const SizedBox(height: 24),
          EduTextField(
            label: 'Price per Session (Rs.)',
            hint: 'Set your hourly rate', 
            icon: Icons.payments_rounded, 
            controller: _priceController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 32),
          const SectionHeader(title: 'Availability'),
          const SizedBox(height: 16),
          const Text('You can manage detailed slots in your dashboard schedule.', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ModernCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].map((day) => CheckboxListTile(
                title: Text(day),
                value: true,
                onChanged: (val) {},
                activeColor: AppTheme.primaryTeal,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: EduPrimaryButton(
        label: _currentStep < 3 ? 'Continue' : 'Save & Go to Dashboard',
        showArrow: _currentStep < 3,
        onPressed: _nextPage,
      ),
    );
  }

  void _showAddQualificationDialog() {
    final tController = TextEditingController();
    final iController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Qualification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tController, decoration: const InputDecoration(hintText: 'Degree / Certification')),
            const SizedBox(height: 12),
            TextField(controller: iController, decoration: const InputDecoration(hintText: 'Institution')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            if (tController.text.isNotEmpty && iController.text.isNotEmpty) {
              setState(() {
                _qualifications.add(Qualification(title: tController.text, institution: iController.text));
              });
            }
            Navigator.pop(context);
          }, child: const Text('Add')),
        ],
      ),
    );
  }
}
