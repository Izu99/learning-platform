import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/app_theme.dart';
import 'package:learning_platform/core/auth_provider.dart';
import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/widgets/edu_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'session_requests_screen.dart';
import 'schedule_management_screen.dart';
import 'profile_management_screen.dart';
import 'live_session_screen.dart';
import '../../widgets/modern_avatar.dart';
import '../../widgets/notification_bell.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    final teacherId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (teacherId == null) return;

    try {
      final response = await ApiService().get('/bookings/teacher/$teacherId');
      if (mounted) {
        setState(() {
          _bookings = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final requests = _bookings.where((b) => b['status'].toString().toLowerCase() == 'pending').toList();
    final upcoming = _bookings.where((b) => b['status'].toString().toLowerCase() == 'accepted').toList();
    final completed = _bookings.where((b) => b['status'].toString().toLowerCase() == 'completed').toList();
    
    final totalSessions = _bookings.length;
    final activeStudents = _bookings.map((b) => b['studentId']).toSet().length;
    final totalEarnings = completed.length * 2500; // Updated placeholder for Sri Lanka context

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('EmuLearn', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryTeal, fontSize: 24)),
        centerTitle: false,
        actions: [
          const NotificationBell(color: AppTheme.primaryTeal),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileManagementScreen())),
            icon: ModernAvatar(
              imageUrl: user?.profileImageUrl, // Assuming User model has this, otherwise we fallback
              fallbackText: user?.name ?? 'Teacher',
              radius: 14,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchBookings,
            color: AppTheme.primaryTeal,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back, ${user?.name ?? 'Teacher'}! 👋', 
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        Text('You have ${upcoming.length + requests.length} total tasks to review.', 
                          style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 15)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Stats Strip (Reference 5.png style)
                  _buildStatsRow(totalSessions, totalEarnings, activeStudents),

                  const SizedBox(height: 32),

                  // Quick Actions (Refined Chips)
                  _buildQuickActionsScroll(),

                  const Divider(height: 48, thickness: 1, color: Color(0xFFF1F5F9)),

                  // Calendar Schedule (Reference 5.png)
                  _buildCalendarSection(upcoming),

                  const Divider(height: 48, thickness: 1, color: Color(0xFFF1F5F9)),

                  // Incoming Requests
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Incoming Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionRequestsScreen())),
                          child: const Text('View All', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (requests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text('No pending requests.', style: TextStyle(color: AppTheme.textMuted)),
                    )
                  else
                    ...requests.take(2).map((b) => _buildRequestCard(b)),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStatsRow(int total, int earnings, int students) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('SESSIONS', '$total'),
            Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
            _buildStatItem('EARNINGS', 'Rs.$earnings'),
            Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
            _buildStatItem('STUDENTS', '$students'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildQuickActionsScroll() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildActionChip(Icons.calendar_month_rounded, 'Manage Schedule', const Color(0xFFE2F2EF), AppTheme.primaryTeal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleManagementScreen()))),
          const SizedBox(width: 12),
          _buildActionChip(Icons.mail_outline_rounded, 'Requests', const Color(0xFFFFF7ED), Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionRequestsScreen()))),
          const SizedBox(width: 12),
          _buildActionChip(Icons.person_outline_rounded, 'My Profile', const Color(0xFFEEF2FF), Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileManagementScreen()))),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, Color bg, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: iconColor, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection(List<dynamic> upcoming) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Teaching Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const Text('Today', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: List.generate(7, (index) {
              final date = DateTime.now().add(Duration(days: index));
              final dayName = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'][date.weekday % 7];
              final isSelected = index == 0;
              return Container(
                width: 65,
                height: 85,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(dayName, 
                      style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 8),
                    Text('${date.day}', style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 18)),
                  ],
                ),
              );
            }),
          ),
        ),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 24),
          ...upcoming.take(2).map((b) => _buildUpcomingSessionCard(b)),
        ],
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> booking) {
    final student = booking['studentId'];
    final name = student != null ? student['name'] : 'Student';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ModernCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        radius: 20,
        child: Row(
          children: [
            ModernAvatar(
              imageUrl: student != null && student is Map ? student['profileImageUrl'] : null,
              fallbackText: name,
              radius: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(booking['topic'] ?? 'General English', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const StatusBadge(label: 'PENDING', color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSessionCard(Map<String, dynamic> booking) {
    final student = booking['studentId'];
    final name = student != null ? student['name'] : 'Student';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ModernCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        radius: 20,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE2F2EF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.videocam_rounded, color: AppTheme.primaryTeal),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking['topic'] ?? 'English Lesson', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('${booking['scheduledTime'].split(' ').last} with $name', 
                    style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveSessionScreen(
                studentName: name, 
                topic: booking['topic'], 
                imageUrl: student != null && student is Map ? student['profileImageUrl'] : null,
              ))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppTheme.primaryTeal, borderRadius: BorderRadius.circular(10)),
                child: const Text('Join', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
