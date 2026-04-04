import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import '../../models/teacher_model.dart';
import 'widgets/profile_header.dart';
import 'widgets/stats_row.dart';
import 'widgets/certifications_list.dart';
import 'widgets/section_title.dart';
import 'widgets/availability_calendar.dart';
import 'widgets/time_slot_grid.dart';
import 'widgets/session_topic_selector.dart';
import 'widgets/custom_request_input.dart';
import 'widgets/bottom_booking_bar.dart';

class TeacherProfileScreen extends StatefulWidget {
  final Teacher teacher;
  final bool isAdminView;

  const TeacherProfileScreen({super.key, required this.teacher, this.isAdminView = false});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  // State for selections
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String? _selectedTopic;
  final _noteController = TextEditingController();
  
  List<String> _fetchedSlots = [];
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    // Initialize with first available date/slot if needed
    if (widget.teacher.availability.isNotEmpty) {
      _selectedDate = DateTime.now();
      _fetchSlots(_selectedDate!);
    }
  }

  Future<void> _fetchSlots(DateTime date) async {
    setState(() => _isLoadingSlots = true);
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final slots = await ApiService().fetchTeacherSlots(widget.teacher.id, dateStr);
      if (mounted) {
        setState(() {
          _fetchedSlots = slots.map((s) => s['time'].toString()).toList();
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = null; 
      _fetchedSlots = [];
    });
    _fetchSlots(date);
  }

  void _onTimeSlotSelected(String slot) {
    setState(() {
      _selectedTimeSlot = slot;
    });
  }

  void _onTopicSelected(String topic) {
    setState(() {
      _selectedTopic = topic;
    });
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white, // Ensure white background as per design
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1B6B5E), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          widget.teacher.price != null && widget.teacher.price! > 0 ? 'Teacher Profile' : 'Student Profile',
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFF1B6B5E), // Deep green — matches S5.png
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF1B6B5E)),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // Space for bottom bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeader(teacher: widget.teacher, isAdminView: widget.isAdminView),
                const SizedBox(height: 24),
                
                StatsRow(teacher: widget.teacher),
                const SizedBox(height: 24),
                
                // Certifications
                if (widget.teacher.qualifications != null && widget.teacher.qualifications!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CertificationsList(qualifications: widget.teacher.qualifications!),
                  ),
                const SizedBox(height: 24),

                // Student Interests / Learning Goals (Student View)
                if (widget.teacher.price == null || widget.teacher.price == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(title: 'Learning Goals'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.teacher.tags.map((goal) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                goal,
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (widget.teacher.about.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const SectionTitle(title: 'Student Bio'),
                          const SizedBox(height: 8),
                          Text(
                            widget.teacher.about,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                // Teacher Sections (Hidden for students)
                if (widget.teacher.price != null && widget.teacher.price! > 0) ...[
                  // About Me
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(title: 'About The Teacher'),
                        const SizedBox(height: 8),
                        Text(
                          widget.teacher.about,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Teaching Topics (Teacher Only)
                if (widget.teacher.price != null && widget.teacher.price! > 0 && widget.teacher.sessionTopics.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Expertise & Topics'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.teacher.sessionTopics.map((topic) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1), // Light teal background
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              topic,
                              style: const TextStyle(
                                color: Color(0xFF00695C), // Dark teal text
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Availability & Booking (Hide for student profiles)
                if (widget.teacher.price != null && widget.teacher.price! > 0) ...[
                  // Availability
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SectionTitle(title: 'Availability'),
                            Text(
                              '${_getMonthName(_selectedDate?.month ?? DateTime.now().month)} ${_selectedDate?.year ?? DateTime.now().year}',
                              style: const TextStyle(
                                color: Color(0xFF009688),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AvailabilityCalendar(
                          selectedDate: _selectedDate,
                          onDateSelected: _onDateSelected,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'AVAILABLE TIME SLOTS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingSlots)
                          const Center(child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: Color(0xFF009688)),
                          ))
                        else
                          TimeSlotGrid(
                            selectedSlot: _selectedTimeSlot,
                            onSlotSelected: _onTimeSlotSelected,
                            slots: _fetchedSlots,
                          ),
                        if (!_isLoadingSlots && _selectedDate != null && _fetchedSlots.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text('No sessions available for this specific date.', 
                              style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Select Session Topic
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(title: 'Select Session Topic'),
                        const SizedBox(height: 12),
                        SessionTopicSelector(
                          topics: widget.teacher.sessionTopics.isNotEmpty 
                              ? widget.teacher.sessionTopics 
                              : (widget.teacher.tags.isNotEmpty ? widget.teacher.tags : ['General English']),
                          selectedTopic: _selectedTopic,
                          onTopicSelected: _onTopicSelected,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Custom Request
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CustomRequestInput(
                      controller: _noteController,
                      teacherName: widget.teacher.name,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
          
          // Bottom Bar (Hide for student profiles or show Admin controls)
          if (widget.isAdminView)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildAdminControlBar(),
            )
          else if (widget.teacher.price != null && widget.teacher.price! > 0)
            Align(
              alignment: Alignment.bottomCenter,
              child: BottomBookingBar(onPressed: _handleBooking),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminControlBar() {
    // Only show status update controls for teachers (those with a price/role)
    if (widget.teacher.price == null || widget.teacher.price == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: const SafeArea(
          child: Center(
            child: Text('Viewing Student Profile (Admin)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }

    final status = (widget.teacher.status ?? 'pending').toLowerCase();
    final isActv = status == 'active' || status == 'approved';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isActv)
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleStatusUpdate('active'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B6B5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Approve Teacher', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            else
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleStatusUpdate('pending'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Set to Pending', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStatusUpdate(String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final pId = widget.teacher.profileId;
      if (pId == null) throw 'Profile ID not found.';
      
      await ApiService().put('/admin/teachers/$pId/status', {'status': newStatus});
      
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Status updated to $newStatus!'), backgroundColor: const Color(0xFF1B6B5E)));
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _handleBooking() async {
    final student = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }
    
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date and time')));
      return;
    }

    try {
      final formattedDay = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      await ApiService().post('/bookings', {
        'teacherId': widget.teacher.id,
        'studentId': student.id,
        'topic': _selectedTopic ?? widget.teacher.tags.firstOrNull ?? 'General English',
        'scheduledTime': '$formattedDay, $_selectedTimeSlot',
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
