import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/app_theme.dart';
import 'package:learning_platform/core/auth_provider.dart';
import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/widgets/edu_widgets.dart';
import 'package:learning_platform/models/teacher_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/modern_avatar.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();
  final _priceController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedLevel = 'Intermediate';
  List<String> _interests = [];
  List<String> _teacherTags = [];
  List<dynamic> _availability = [];

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    _nameController.text = user.name;
    _selectedLevel = user.level ?? 'Intermediate';
    _interests = List<String>.from(user.interests ?? []);

    final role = user.role.toLowerCase();
    
    if (role == 'teacher') {
      try {
        final response = await ApiService().get('/teachers/profile/${user.id}');
        if (mounted) {
          setState(() {
            _titleController.text = response['title'] ?? '';
            _bioController.text = response['bio'] ?? '';
            _priceController.text = (response['price'] ?? 0).toString();
            _teacherTags = List<String>.from(response['tags'] ?? []);
            _availability = response['availability'] ?? [];
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      final role = user?.role.toLowerCase() ?? '';
      
      // Update basic user preferences (primarily for students)
      if (role == 'student') {
        await ApiService().post('/auth/preferences', {
          'interests': _interests,
          'level': _selectedLevel,
        });

        // Update provider locally
        Provider.of<AuthProvider>(context, listen: false).updateUserPreferences(
          interests: _interests,
          level: _selectedLevel,
        );
      }

      // If user is a teacher, only update teacher-specific profile details
      if (role == 'teacher') {
        await ApiService().post('/teachers/profile', {
          'userId': user?.id,
          'title': _titleController.text,
          'bio': _bioController.text,
          'price': double.tryParse(_priceController.text) ?? 35,
          'tags': _teacherTags,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: AppTheme.primaryTeal,
          )
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isSaving) 
            const Center(child: Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal)))),
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryTeal, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo Section (Inspired by 5.png)
                _buildPhotoHeader(),
                
                const SizedBox(height: 32),
                
                // Public Information (Decoupled Teachers vs Students)
                if (user?.role.toLowerCase() == 'teacher') ...[
                  _buildSectionTitle('Public Teacher Profile'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildTextField('Full Name', Icons.person_outline_rounded, _nameController),
                        const SizedBox(height: 20),
                        _buildTextField('Professional Title', Icons.work_outline_rounded, _titleController),
                        const SizedBox(height: 20),
                        _buildTextField('Biography / Teaching Style', Icons.history_edu_rounded, _bioController, maxLines: 4),
                      ],
                    ),
                  ),
                ] else ...[
                  _buildSectionTitle('Student Profile Information'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildTextField('Full Name', Icons.person_outline_rounded, _nameController),
                        const SizedBox(height: 20),
                        _buildTextField('Introduce Yourself to Teachers', Icons.face_rounded, _bioController, maxLines: 3),
                        const SizedBox(height: 12),
                        Text('Teachers want to know your current status and reasons for learning English.', 
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
                
                const Divider(height: 64, thickness: 1, color: Color(0xFFF1F5F9)),
                
                // Role-Specific Sections (Student Goals vs Teacher Pricing)
                if (user?.role.toLowerCase() == 'student') ...[
                  // Student Level Selection
                  _buildSectionTitle('English Proficiency Level'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ['Beginner', 'Intermediate', 'Advanced'].map((level) {
                        final isSelected = _selectedLevel == level;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedLevel = level),
                          child: AnimatedContainer(
                            duration: 250.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryTeal : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? AppTheme.primaryTeal : const Color(0xFFE2E8F0)),
                            ),
                            child: Text(level, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const Divider(height: 64, thickness: 1, color: Color(0xFFF1F5F9)),

                  // Learning Interests
                  _buildSectionTitle('Learning Interests'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 12,
                          children: [
                            ..._interests.map((interest) => _buildInterestChip(interest)),
                            GestureDetector(
                              onTap: _showAddInterestDialog,
                              child: _buildAddButton('Add Interest'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Tell teachers what you want to focus on (e.g., IELTS, Public Speaking)', 
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ] else if (user?.role.toLowerCase() == 'teacher') ...[
                  // Teacher-Specific Sections
                  _buildSectionTitle('Pricing & Rate'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildTextField('Hourly Rate (Rs.)', Icons.payments_rounded, _priceController, keyboardType: TextInputType.number),
                  ),

                  const Divider(height: 64, thickness: 1, color: Color(0xFFF1F5F9)),

                  _buildSectionTitle('Teaching Topics'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 12,
                          children: [
                            ..._teacherTags.map((tag) => _buildInterestChip(tag, isTeacher: true)),
                            GestureDetector(
                              onTap: _showAddTagDialog,
                              child: _buildAddButton('Add Topic'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 40),
                
                // View Public Profile Link
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
                      if (user == null) return;
                      final role = user.role.toLowerCase();

                      final previewTeacher = Teacher(
                        id: user.id,
                        name: _nameController.text.isNotEmpty ? _nameController.text : user.name,
                        title: role == 'student' ? 'Student' : (_titleController.text.isNotEmpty ? _titleController.text : 'English Teacher'),
                        about: _bioController.text,
                        price: role == 'teacher' ? (double.tryParse(_priceController.text) ?? 35) : null,
                        tags: role == 'teacher' ? _teacherTags : _interests,
                        sessionTopics: role == 'teacher' ? _teacherTags : _interests,
                        location: 'Remote',
                        rating: 0.0,
                        studentsCount: 0,
                        lessonsCount: 0,
                        hoursCount: 0,
                        experienceYears: 0,
                        isVerified: role == 'teacher',
                        isOnline: true,
                        availability: role == 'teacher' ? (_availability.map((a) => a['day']?.toString() ?? '').toList()) : [],
                        timeSlots: role == 'teacher' 
                            ? (_availability.isNotEmpty && _availability[0]['slots'] != null
                                ? (_availability[0]['slots'] as List).map((s) => TimeSlot.fromJson(s)).toList() 
                                : [])
                            : [],
                        qualifications: [],
                        profileImageUrl: user.profileImageUrl,
                      );
                      Navigator.pushNamed(context, '/teacher-profile', arguments: previewTeacher);
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    label: const Text('Preview Public Profile', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPhotoHeader() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: ModernAvatar(
                imageUrl: Provider.of<AuthProvider>(context).currentUser?.profileImageUrl,
                fallbackText: Provider.of<AuthProvider>(context).currentUser?.name ?? 'T',
                radius: 60,
              ),
            ),
          ),
          Positioned(
            bottom: -4,
            right: -4,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestChip(String label, {bool isTeacher = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F2EF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                if (isTeacher) {
                  _teacherTags.remove(label);
                } else {
                  _interests.remove(label);
                }
              });
            },
            child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.primaryTeal),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryTeal, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_rounded, size: 18, color: AppTheme.primaryTeal),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add Teaching Topic', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'e.g. TOEFL Preparation',
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _teacherTags.add(controller.text));
                Navigator.pop(context);
              }
            }, 
            child: const Text('Add', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  void _showAddInterestDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add Learning Interest', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'e.g. TOEFL Preparation',
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _interests.add(controller.text));
                Navigator.pop(context);
              }
            }, 
            child: const Text('Add', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}
