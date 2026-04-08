import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/app_theme.dart';
import 'package:learning_platform/core/auth_provider.dart';
import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/models/booking_model.dart';
import 'package:learning_platform/widgets/edu_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/modern_avatar.dart';
import 'package:intl/intl.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<Booking> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final studentId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (studentId == null) return;

    try {
      final response = await ApiService().get('/bookings/student/$studentId') as List;
      if (mounted) {
        setState(() {
          _requests = List<Booking>.from((response as List).map((data) => Booking.fromJson(data)));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRescheduleAction(Booking b, String status) async {
    try {
      final body = <String, String>{'status': status};
      // If student accepts the teacher's suggested time, update scheduledTime
      if (status == 'Accepted' && b.suggestedTime != null) {
        body['scheduledTime'] = b.suggestedTime!;
      }

      await ApiService().patch('/bookings/${b.id}/status', body);
      _fetchRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $status!'), backgroundColor: Colors.green),
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

  Future<void> _showRescheduleDialog(Booking booking) async {
    DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    try {
      selectedDateTime = _parseBookingTime(booking.scheduledTime);
    } catch (_) {}

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Request Reschedule', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pick a new time to suggest to your teacher:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryTeal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat('MMM dd, hh:mm a').format(selectedDateTime),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_calendar_rounded, color: AppTheme.primaryTeal),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null && context.mounted) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedDateTime = DateTime(
                                date.year, date.month, date.day, time.hour, time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'QUICK DELAY',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [5, 10, 15, 30].map((mins) => ActionChip(
                  label: Text('+$mins min'),
                  onPressed: () => setDialogState(() {
                    selectedDateTime = selectedDateTime.add(Duration(minutes: mins));
                  }),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            EduPrimaryButton(
              label: 'Send Request',
              onPressed: () {
                Navigator.pop(context);
                _submitReschedule(booking, selectedDateTime.toUtc().toIso8601String());
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReschedule(Booking booking, String newTime) async {
    try {
      await ApiService().patch('/bookings/${booking.id}/status', {
        'status': 'Rescheduled',
        'suggestedTime': newTime,
      });
      _fetchRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reschedule request sent to teacher!'),
            backgroundColor: AppTheme.primaryTeal,
          ),
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

  // Parse a booking time string safely (handles both Z-suffix and plain local times)
  DateTime _parseBookingTime(String iso) {
    // Strip Z to treat time as local (times are entered in local timezone)
    final localIso = iso.endsWith('Z') ? iso.replaceAll('Z', '') : iso;
    return DateTime.parse(localIso);
  }

  String _fmt(String iso) {
    try {
      return DateFormat('MMM dd, yyyy  hh:mm a').format(_parseBookingTime(iso));
    } catch (e) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppDesignTokens>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('My Booking Requests')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRequests,
              child: _requests.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        return _StudentRequestCard(
                          booking: _requests[index],
                          tokens: tokens,
                          fmt: _fmt,
                          onAcceptReschedule: () => _handleRescheduleAction(_requests[index], 'Accepted'),
                          onRejectReschedule: () => _handleRescheduleAction(_requests[index], 'Rejected'),
                          onRequestReschedule: () => _showRescheduleDialog(_requests[index]),
                        )
                            .animate(delay: (index * 50).ms)
                            .fadeIn()
                            .slideY(begin: 0.1);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: AppTheme.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No booking requests found', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _StudentRequestCard extends StatelessWidget {
  final Booking booking;
  final AppDesignTokens tokens;
  final String Function(String) fmt;
  final VoidCallback onAcceptReschedule;
  final VoidCallback onRejectReschedule;
  final VoidCallback onRequestReschedule;

  const _StudentRequestCard({
    required this.booking,
    required this.tokens,
    required this.fmt,
    required this.onAcceptReschedule,
    required this.onRejectReschedule,
    required this.onRequestReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final isAccepted = booking.status.toLowerCase() == 'accepted';
    // Teacher suggested a new time and is waiting for student response
    final teacherSuggestedReschedule = booking.status.toLowerCase() == 'rescheduled' &&
        booking.suggestedTime != null &&
        booking.rescheduledBy != 'student';
    // Student already sent a reschedule request, waiting for teacher
    final studentPendingReschedule = booking.status.toLowerCase() == 'rescheduled' &&
        booking.rescheduledBy == 'student';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [tokens.softShadow],
        border: Border.all(
          color: teacherSuggestedReschedule
              ? Colors.orange.withOpacity(0.3)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                ModernAvatar(
                  imageUrl: booking.teacherProfileImageUrl,
                  fallbackText: booking.teacherName ?? 'T',
                  radius: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.teacherName ?? 'Teacher',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      StatusBadge(label: booking.topic, color: AppTheme.primaryBlue),
                    ],
                  ),
                ),
                StatusBadge(label: booking.status.toUpperCase(), color: statusColor),
              ],
            ),
            const SizedBox(height: 16),

            // Scheduled time
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fmt(booking.scheduledTime),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            // Teacher suggested reschedule → student can Accept or Reject
            if (teacherSuggestedReschedule) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_repeat_rounded, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Teacher suggested a new time:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fmt(booking.suggestedTime!),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onAcceptReschedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTeal,
                              minimumSize: const Size(double.infinity, 40),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Accept New Time',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onRejectReschedule,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentRed,
                              side: const BorderSide(color: AppTheme.accentRed),
                              minimumSize: const Size(double.infinity, 40),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Student already requested a reschedule → show waiting state
            if (studentPendingReschedule) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your reschedule request is pending teacher review',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          if (booking.suggestedTime != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Suggested: ${fmt(booking.suggestedTime!)}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // For accepted bookings, student can request a reschedule
            if (isAccepted) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRequestReschedule,
                icon: const Icon(Icons.event_repeat_rounded, size: 16),
                label: const Text('Request Reschedule', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryTeal,
                  side: const BorderSide(color: AppTheme.primaryTeal),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppTheme.primaryTeal;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return AppTheme.accentRed;
      case 'rescheduled':
        return Colors.orange;
      default:
        return AppTheme.textSecondary;
    }
  }
}
