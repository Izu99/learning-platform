import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/app_theme.dart';
import '../../core/api_service.dart';
import '../../core/auth_provider.dart';
import '../../widgets/modern_avatar.dart';
import 'package:learning_platform/models/teacher_model.dart';
import 'package:learning_platform/widgets/edu_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class TeacherDetailScreen extends StatefulWidget {
  final Teacher teacher;
  const TeacherDetailScreen({super.key, required this.teacher});

  @override
  State<TeacherDetailScreen> createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends State<TeacherDetailScreen> {
  int _selectedDayIndex = 0;
  int _selectedSlotIndex = 0;
  String? _selectedTopic;
  List<DateTime> _next7Days = [];
  List<dynamic> _slicedSlots = [];
  bool _isSlotsLoading = false;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateCalendar();
    if (widget.teacher.tags.isNotEmpty) {
      _selectedTopic = widget.teacher.tags.first;
    }
  }

  void _generateCalendar() {
    final now = DateTime.now();
    _next7Days = List.generate(7, (i) => now.add(Duration(days: i)));
    _fetchAvailableSlots(_next7Days[0]);
  }

  Future<void> _fetchAvailableSlots(DateTime date) async {
    setState(() => _isSlotsLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await ApiService().get('/teachers/${widget.teacher.id}/available-slots?date=$dateStr');
      if (mounted) {
        setState(() {
          _slicedSlots = List<dynamic>.from(response);
          _selectedSlotIndex = 0;
          _isSlotsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSlotsLoading = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.teacher;
    final tokens = Theme.of(context).extension<AppDesignTokens>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(t),
                  const SizedBox(height: 32),
                  _buildStatsRow(t, tokens),
                  const SizedBox(height: 32),
                  if (t.qualifications != null && t.qualifications!.isNotEmpty)
                    _buildQualifications(t.qualifications!),
                  const SizedBox(height: 32),
                  const SectionHeader(title: 'About Me'),
                  const SizedBox(height: 12),
                  Text(t.about, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, color: AppTheme.textSecondary)),
                  const SizedBox(height: 32),
                  const SectionHeader(title: 'Teaching Topics'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: t.tags.map((tag) => _ModernTag(label: tag)).toList(),
                  ),
                  const SizedBox(height: 32),
                  const SectionHeader(title: 'Availability'),
                  const SizedBox(height: 16),
                  _buildCalendar(t),
                  const SizedBox(height: 24),
                  _buildTimeSlots(t),
                  const SizedBox(height: 32),
                  const SectionHeader(title: 'Select Session Topic'),
                  const SizedBox(height: 16),
                  _buildTopicSelector(t),
                  const SizedBox(height: 32),
                  const SectionHeader(title: 'Custom Request / Note'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tell ${t.name.split(' ').first} what you\'d like to focus on...',
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildBottomAction(tokens),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Teacher t) {
    return Row(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: t.profileImageUrl != null
                  ? Image.network(
                      t.profileImageUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: const Color(0xFFE2F2EF),
                      alignment: Alignment.center,
                      child: Text(
                        t.name.isNotEmpty ? t.name[0].toUpperCase() : 'T',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF00695C)),
                      ),
                    ),
            ),
            if (t.isVerified)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.name, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24)),
              const SizedBox(height: 4),
              Text(t.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryTeal, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 4),
                  Text(t.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(' (${t.lessonsCount} lessons)', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Teacher t, AppDesignTokens tokens) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(label: 'EXPERIENCE', value: '${t.experienceYears}y'),
          _VerticalDivider(),
          _StatItem(label: 'STUDENTS', value: '${t.studentsCount}+'),
          _VerticalDivider(),
          _StatItem(label: 'RATE', value: 'Rs.${t.price?.toStringAsFixed(0) ?? '0'}/hr'),
        ],
      ),
    );
  }

  Widget _buildQualifications(List<Qualification> quals) {
    return Column(
      children: quals.map((q) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: _CertBadge(icon: Icons.school_rounded, label: '${q.title} • ${q.institution}'),
      )).toList(),
    );
  }  Widget _buildCalendar(Teacher t) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_next7Days.length, (index) {
          final isSelected = _selectedDayIndex == index;
          final date = _next7Days[index];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDayIndex = index);
              _fetchAvailableSlots(date);
            },
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryTeal : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
                boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryTeal.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
              ),
              child: Column(
                children: [
                  Text(DateFormat('EEE').format(date).toUpperCase(), 
                    style: TextStyle(color: isSelected ? Colors.white70 : AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(DateFormat('dd').format(date), 
                    style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeSlots(Teacher t) {
    if (_isSlotsLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal));
    if (_slicedSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 40, color: AppTheme.textMuted.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('No available 40min slots for this day.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('AVAILABLE 40MIN SLOTS', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800)),
            Text('(+5m buffer)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontStyle: FontStyle.italic)),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _slicedSlots.length,
          itemBuilder: (context, index) {
            final slot = _slicedSlots[index];
            final isSelected = _selectedSlotIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedSlotIndex = index),
              child: AnimatedContainer(
                duration: 200.ms,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryTeal.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppTheme.primaryTeal : const Color(0xFFE2E8F0), width: 1.5),
                ),
                child: Text(slot['time'], style: TextStyle(color: isSelected ? AppTheme.primaryTeal : AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopicSelector(Teacher t) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: t.tags.map((topic) {
        final isSelected = _selectedTopic == topic;
        return GestureDetector(
          onTap: () => setState(() => _selectedTopic = topic),
          child: AnimatedContainer(
            duration: 200.ms,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryTeal : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
            ),
            child: Text(topic, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomAction(AppDesignTokens tokens) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [tokens.deepShadow],
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: EduPrimaryButton(
        label: 'Send Booking Request',
        color: AppTheme.primaryTeal,
        onPressed: _handleBooking,
      ),
    );
  }

  Future<void> _handleBooking() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final student = authProvider.currentUser;
    if (student == null) return;

    if (_slicedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No slots available to book!')));
      return;
    }

    try {
      final slot = _slicedSlots[_selectedSlotIndex];
      
      await ApiService().post('/bookings', {
        'teacherId': widget.teacher.id,
        'studentId': student.id,
        'topic': _selectedTopic,
        'scheduledTime': slot['fullDateTime'],
        'notes': _noteController.text,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request sent successfully!'), backgroundColor: AppTheme.primaryTeal),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e'), backgroundColor: AppTheme.accentRed));
      }
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 30, color: const Color(0xFFE2E8F0));
}

class _CertBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CertBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _ModernTag extends StatelessWidget {
  final String label;
  const _ModernTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.tagBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: AppTheme.tagText, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
