import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/app_theme.dart';
import 'package:learning_platform/core/auth_provider.dart';
import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/models/booking_model.dart';
import 'package:learning_platform/widgets/edu_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/modern_avatar.dart';
import 'package:learning_platform/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionRequestsScreen extends StatefulWidget {
  const SessionRequestsScreen({super.key});

  @override
  State<SessionRequestsScreen> createState() => _SessionRequestsScreenState();
}

class _SessionRequestsScreenState extends State<SessionRequestsScreen> {
  List<Booking> _requests = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final teacherId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (teacherId == null) return;

    if (_requests.isEmpty) setState(() => _isLoading = true);
    try {
      final response = await ApiService().get('/bookings/teacher/$teacherId'); 
      if (mounted) {
        setState(() {
          _requests = List<Booking>.from((response as List).map((json) => Booking.fromJson(json)));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load requests: $e')));
      }
    }
  }

  Future<void> _updateStatus(String id, String status, {String? suggestedTime, String? scheduledTime}) async {
    try {
      final body = {'status': status};
      if (suggestedTime != null) body['suggestedTime'] = suggestedTime;
      if (scheduledTime != null) body['scheduledTime'] = scheduledTime;

      await ApiService().patch('/bookings/$id/status', body);
      _fetchRequests();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $status successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateBookingDetails(Booking b, String newTopic, String newTime) async {
    try {
      await ApiService().patch('/bookings/${b.id}/status', {
        'topic': newTopic,
        'scheduledTime': newTime,
      });
      _fetchRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  void _showEditDialog(Booking booking) {
    final topicController = TextEditingController(text: booking.topic);
    final timeController = TextEditingController(text: booking.scheduledTime);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Request Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: topicController,
              decoration: const InputDecoration(labelText: 'Topic'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: 'Scheduled Time'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateBookingDetails(booking, topicController.text, timeController.text);
            },
            child: const Text('Save Changes', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showRescheduleDialog(Booking booking) async {
    DateTime selectedDateTime = DateTime.parse(booking.scheduledTime);
    
    // Helper to format ISO
    String formatISO(DateTime dt) => dt.toUtc().toIso8601String();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Reschedule Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pick a new time or add a quick delay:', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              
              // Date/Time Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryTeal),
                    const SizedBox(width: 12),
                    Expanded(child: Text(DateFormat('MMM dd, hh:mm a').format(selectedDateTime), 
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                    IconButton(
                      icon: const Icon(Icons.edit_calendar_rounded, color: AppTheme.primaryTeal),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Safety Warning Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentRed.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security_rounded, size: 16, color: AppTheme.accentRed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'For your safety and protection, never share personal contact details. EmuLearn only guarantees payments and quality for sessions booked inside the app.',
                        style: TextStyle(color: AppTheme.accentRed.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              const Align(alignment: Alignment.centerLeft, child: Text('QUICK DELAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [5, 10, 15, 30].map((mins) => ActionChip(
                  label: Text('+$mins min'),
                  onPressed: () {
                    setDialogState(() {
                      selectedDateTime = selectedDateTime.add(Duration(minutes: mins));
                    });
                  },
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            EduPrimaryButton(
              label: 'Send Suggestion',
              onPressed: () {
                Navigator.pop(context);
                _updateStatus(booking.id, 'Rescheduled', suggestedTime: formatISO(selectedDateTime));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetails(String studentId, Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder<dynamic>(
        future: ApiService().get('/admin/students/$studentId'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingBottomSheet();
          } else if (snapshot.hasError) {
            return _buildErrorBottomSheet('Failed to load student details: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data == null) {
            return _buildErrorBottomSheet('Student details not found.');
          }

          // Assuming the API returns a map that can be converted to a User model
          final student = User.fromJson(snapshot.data);
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        ModernAvatar(
                          imageUrl: student.profileImageUrl,
                          fallbackText: student.name.isNotEmpty ? student.name[0] : 'S',
                          radius: 50,
                        ),
                        const SizedBox(height: 16),
                        Text(student.name, 
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _DetailBadge(
                              icon: Icons.bar_chart_rounded, 
                              label: student.level ?? 'Not Specified',
                              color: AppTheme.primaryGreen,
                            ),
                          ],
                        ),
                        if (Provider.of<AuthProvider>(context, listen: false).isAdmin && student.phoneNumber != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone_android_rounded, color: AppTheme.primaryGreen, size: 18),
                                const SizedBox(width: 8),
                                Text(student.phoneNumber!, style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 32),
                        
                        // Registration Date
                        if (student.registrationDate != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.app_registration, color: AppTheme.textSecondary),
                                const SizedBox(width: 8),
                                Text('Registered: ${student.registrationDate}', style: const TextStyle(color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Learning Interests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        if (student.interests == null || student.interests!.isEmpty)
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('No specific interests listed.', style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.start,
                            children: student.interests!.map((interest) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.tagBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(interest, style: const TextStyle(color: AppTheme.tagText, fontWeight: FontWeight.w700, fontSize: 13)),
                            )).toList(),
                          ),
                        
                        const SizedBox(height: 32),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Session Request Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        // Display booking specific notes
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20)),
                          child: Text(booking.notes ?? 'No additional notes provided for this session request.', 
                            style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: EduPrimaryButton(label: 'Close Detail', onPressed: () => Navigator.pop(context)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorBottomSheet(String message) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  List<Booking> get _filteredRequests {
    if (_selectedFilter == 'All') return _requests;
    return _requests.where((r) => r.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  String _fmt(String iso) {
    try {
      // Strip Z suffix so times are treated as local (times are stored as local wall-clock)
      final localIso = iso.endsWith('Z') ? iso.replaceAll('Z', '') : iso;
      return DateFormat('MMM dd, yyyy  hh:mm a').format(DateTime.parse(localIso));
    } catch (e) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('E', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 8),
            const Text('EmuLearn', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B)),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : RefreshIndicator(
                    onRefresh: _fetchRequests,
                    color: AppTheme.primaryGreen,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$_selectedFilter Requests', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                              const SizedBox(height: 8),
                              const Text('Review and manage incoming student requests.', 
                                style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500, fontSize: 16)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_filteredRequests.isNotEmpty) ...[
                          ..._filteredRequests.map((r) => _buildRequestCard(r)).toList().animate(interval: 50.ms).fadeIn().slideY(begin: 0.1),
                        ],
                        if (_filteredRequests.isEmpty) _buildEmptyState(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ['All', 'Pending', 'Accepted', 'Rejected', 'Rescheduled'];
    return Container(
      height: 70,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              onPressed: () => setState(() => _selectedFilter = filter),
              label: Text(filter, style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              )),
              backgroundColor: isSelected ? AppTheme.primaryGreen : const Color(0xFFF1F5F9),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Booking request) {
    final isPending = request.status.toLowerCase() == 'pending';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Edit Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ID : ${request.id.substring(request.id.length - 8).toUpperCase()}', 
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 15)),
              if (isPending)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryGreen),
                      onPressed: () => _showEditDialog(request),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                  ],
                ),
            ],
          ),
          const Divider(height: 32, thickness: 1, color: Color(0xFFF1F5F9)),
          
          // Student Profile Summary
          GestureDetector(
            onTap: () => _showStudentDetails(request.studentId, request),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ModernAvatar(
                      imageUrl: request.studentProfileImageUrl,
                      fallbackText: request.studentName ?? 'S',
                      radius: 26,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        request.studentName ?? 'Student', 
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 68), // Align with name start
                      child: Text(request.studentLevel ?? 'Intermediate Level', 
                         style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    TextButton.icon(
                      onPressed: () => _showStudentDetails(request.studentId, request),
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text('View Detail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Data Fields (Vertical Layout)
          _buildInfoRow('Topic', request.topic, valueColor: AppTheme.primaryGreen),
          const SizedBox(height: 12),
          _buildInfoRow('Time', _fmt(request.scheduledTime)),
          if (request.status == 'Rescheduled' && request.suggestedTime != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              request.rescheduledBy == 'student' ? 'Student Suggests' : 'Suggested',
              _fmt(request.suggestedTime!),
              valueColor: AppTheme.primaryGreen,
            ),
          ],
          const SizedBox(height: 12),
          _buildInfoRow('Status', request.status, 
            valueColor: _getStatusColor(request.status), valueWeight: FontWeight.w900),

          if (request.status.toLowerCase() == 'accepted' && request.meetingLink != null) ...[
            const SizedBox(height: 24),
            if (request.meetingPassword != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                    Text('Meeting Passcode: ${request.meetingPassword}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Safety Warning Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentRed.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, size: 16, color: AppTheme.accentRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'For your safety and protection, never share personal contact details. EmuLearn only guarantees payments and quality for sessions booked inside the app.',
                      style: TextStyle(color: AppTheme.accentRed.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            EduPrimaryButton(
              label: 'Join Classroom Now',
              onPressed: () async {
                final uri = Uri.parse(request.meetingLink!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],

          if (isPending) ...[
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Accept',
                    color: AppTheme.primaryTeal,
                    onTap: () => _updateStatus(request.id, 'Accepted'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'Reject',
                    color: const Color(0xFFEF4444),
                    onTap: () => _updateStatus(request.id, 'Rejected'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'Reschedule',
                    color: const Color(0xFF64748B),
                    onTap: () => _showRescheduleDialog(request),
                  ),
                ),
              ],
            ),
          ],

          // Student requested a reschedule → teacher can accept or reject
          if (request.status == 'Rescheduled' && request.rescheduledBy == 'student') ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_repeat_rounded, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${request.studentName ?? 'Student'} requested a reschedule',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Accept New Time',
                          color: AppTheme.primaryTeal,
                          onTap: () => _updateStatus(
                            request.id,
                            'Accepted',
                            scheduledTime: request.suggestedTime,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          label: 'Reject',
                          color: const Color(0xFFEF4444),
                          onTap: () => _updateStatus(request.id, 'Rejected'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, FontWeight? valueWeight, bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text('$label', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        const Text(': ', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(value, 
            style: TextStyle(
              color: valueColor ?? const Color(0xFF1E293B), 
              fontWeight: valueWeight ?? (isBold ? FontWeight.w800 : FontWeight.w600),
              fontSize: 15,
            )),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted': return AppTheme.primaryTeal;
      case 'rejected': return AppTheme.accentRed;
      case 'rescheduled': return const Color(0xFF64748B);
      case 'pending': return Colors.orange;
      default: return Colors.orange;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          Text('No $_selectedFilter requests yet', style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700, fontSize: 18)),
        ],
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(label, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
