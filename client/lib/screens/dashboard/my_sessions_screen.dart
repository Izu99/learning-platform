import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/app_theme.dart';
import 'package:learning_platform/core/auth_provider.dart';
import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/models/booking_model.dart';
import 'package:learning_platform/widgets/edu_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'live_session_screen.dart';
import '../../widgets/modern_avatar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class MySessionsScreen extends StatefulWidget {
  const MySessionsScreen({super.key});

  @override
  State<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends State<MySessionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSessions() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      final endpoint = user.role == 'Teacher' ? '/bookings/teacher/${user.id}' : '/bookings/student/${user.id}';
      final response = await ApiService().get(endpoint) as List;
      if (mounted) {
        setState(() {
          _bookings = List<Booking>.from(response.map((data) => Booking.fromJson(data)));
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
      if (status == 'Accepted' && b.suggestedTime != null) {
        body['scheduledTime'] = b.suggestedTime!;
      }
      await ApiService().patch('/bookings/${b.id}/status', body);
      _fetchSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session $status!'), backgroundColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    final upcoming = _bookings.where((b) => b.status.toLowerCase() == 'accepted').toList();
    final rescheduled = _bookings.where((b) => b.status.toLowerCase() == 'rescheduled').toList();
    final history = _bookings.where((b) => ['completed', 'rejected', 'cancelled'].contains(b.status.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sessions'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryTeal,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            const Tab(text: 'Upcoming'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Rescheduled'),
                  if (rescheduled.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                      child: Text('${rescheduled.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingList(upcoming),
                _buildRescheduledList(rescheduled),
                _buildList(history, true),
              ],
            ),
    );
  }

  String _fmt(String iso) {
    try {
      return DateFormat('MMM dd, hh:mm a').format(DateTime.parse(iso).toLocal());
    } catch (e) {
      return iso;
    }
  }

  Widget _buildUpcomingList(List<Booking> list) {
    if (list.isEmpty) return const Center(child: Text('No upcoming sessions.'));
    return RefreshIndicator(
      onRefresh: _fetchSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final b = list[index];
          return _SessionCard(
            teacherName: b.teacherName ?? 'Teacher',
            topic: b.topic,
            time: _fmt(b.scheduledTime),
            isPast: false,
            imageUrl: b.teacherProfileImageUrl,
            meetingLink: b.meetingLink,
            meetingPassword: b.meetingPassword,
            onJoin: () async {
              if (b.meetingLink != null) {
                final uri = Uri.parse(b.meetingLink!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
          ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.1);
        },
      ),
    );
  }

  Widget _buildRescheduledList(List<Booking> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_repeat_rounded, size: 64, color: AppTheme.textMuted.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('No rescheduled sessions.', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final b = list[index];
          return _RescheduleCard(
            booking: b,
            onAccept: () => _handleRescheduleAction(b, 'Accepted'),
            onReject: () => _handleRescheduleAction(b, 'Rejected'),
          ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.1);
        },
      ),
    );
  }

  Widget _buildList(List<Booking> list, bool isPast) {
    if (list.isEmpty) return Center(child: Text(isPast ? 'No session history found.' : 'No upcoming sessions.'));
    return RefreshIndicator(
      onRefresh: _fetchSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final b = list[index];
          return _SessionCard(
            teacherName: b.teacherName ?? 'Teacher',
            topic: b.topic,
            time: _fmt(b.scheduledTime),
            isPast: isPast,
            imageUrl: b.teacherProfileImageUrl,
            meetingLink: b.meetingLink,
            meetingPassword: b.meetingPassword,
            onJoin: () async {
              if (b.meetingLink != null) {
                final uri = Uri.parse(b.meetingLink!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
          ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.1);
        },
      ),
    );
  }
}

// ── Reschedule card shown in the "Rescheduled" tab ───────────────────────────

class _RescheduleCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RescheduleCard({required this.booking, required this.onAccept, required this.onReject});

  String _fmt(String iso) {
    try {
      return DateFormat('MMM dd, hh:mm a').format(DateTime.parse(iso).toLocal());
    } catch (e) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppDesignTokens>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [tokens.softShadow],
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                ModernAvatar(imageUrl: booking.teacherProfileImageUrl, fallbackText: booking.teacherName ?? 'T', radius: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.teacherName ?? 'Teacher',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(booking.topic,
                          style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Text('RESCHEDULED',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w800, fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Original time (crossed out)
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text('Original: ${_fmt(booking.scheduledTime)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, decoration: TextDecoration.lineThrough, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),

            // Suggested new time (highlighted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.event_repeat_rounded, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text('Suggested: ${booking.suggestedTime != null ? _fmt(booking.suggestedTime!) : 'N/A'}',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Accept New Time',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentRed,
                      side: const BorderSide(color: AppTheme.accentRed),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Normal upcoming/history session card ─────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final String teacherName;
  final String topic;
  final String time;
  final bool isPast;
  final String? imageUrl;
  final String? meetingLink;
  final String? meetingPassword;
  final VoidCallback onJoin;

  const _SessionCard(
      {required this.teacherName,
      required this.topic,
      required this.time,
      required this.isPast,
      this.imageUrl,
      this.meetingLink,
      this.meetingPassword,
      required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppDesignTokens>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [tokens.softShadow],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                ModernAvatar(imageUrl: imageUrl, fallbackText: teacherName, radius: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(teacherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(topic,
                          style: const TextStyle(
                              color: AppTheme.primaryTeal, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
                if (!isPast) const StatusBadge(label: 'CONFIRMED', color: AppTheme.primaryTeal),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(time, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            if (meetingPassword != null && !isPast) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text('Passcode: $meetingPassword', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Safety Training/Warning Banner
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
            ],
            const SizedBox(height: 24),
            isPast
                ? OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.star_rounded, size: 18),
                    label: const Text('Rate Teacher'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                : EduPrimaryButton(
                    label: 'Join Now', 
                    onPressed: meetingLink != null ? onJoin : () {},
                  ),
          ],
        ),
      ),
    );
  }
}
