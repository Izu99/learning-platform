import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/app_theme.dart';
import 'package:learning_platform/core/auth_provider.dart';
import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/models/booking_model.dart';
import 'package:learning_platform/widgets/edu_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/modern_avatar.dart';

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
      final body = {'status': status};
      // If student accepts rescheduled time, we update the scheduledTime to the suggested one
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
                          onAction: (status) => _handleRescheduleAction(_requests[index], status),
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
  final Function(String) onAction;

  const _StudentRequestCard({required this.booking, required this.tokens, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final hasSuggestedTime = booking.suggestedTime != null && booking.status.toLowerCase() == 'rescheduled';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      Text(booking.teacherName ?? 'Teacher', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      StatusBadge(label: booking.topic, color: AppTheme.primaryBlue),
                    ],
                  ),
                ),
                StatusBadge(label: booking.status.toUpperCase(), color: statusColor),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(booking.scheduledTime, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            if (hasSuggestedTime) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('Teacher suggested a new time:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(booking.suggestedTime!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => onAction('Accepted'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              minimumSize: const Size(double.infinity, 40),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Accept New Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => onAction('Rejected'),
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
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted': return AppTheme.primaryTeal;
      case 'pending': return Colors.orange;
      case 'rejected': return AppTheme.accentRed;
      case 'rescheduled': return Colors.orange;
      default: return AppTheme.textSecondary;
    }
  }
}
