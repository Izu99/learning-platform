import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/app_theme.dart';
import 'package:learning_platform/core/auth_provider.dart';
import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/models/booking_model.dart';
import 'package:learning_platform/models/teacher_model.dart';
import 'package:learning_platform/widgets/edu_widgets.dart';
import 'teacher_list_screen.dart';
import 'teacher_detail_screen.dart';
import '../../widgets/modern_avatar.dart';
import '../../widgets/notification_bell.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List<Booking> _bookings = [];
  List<Teacher> _recommendedTeachers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final studentId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (studentId == null) return;

    try {
      final bResponse = await ApiService().get('/bookings/student/$studentId') as List;
      final tResponse = await ApiService().get('/teachers') as List;
      
      if (mounted) {
        setState(() {
          _bookings = List<Booking>.from((bResponse as List).map((data) => Booking.fromJson(data)));
          _recommendedTeachers = List<Teacher>.from((tResponse as List).map((data) => Teacher.fromJson(data)));
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
    final upcoming = _bookings.where((b) => b.status.toLowerCase() == 'accepted').toList();
    final completedCount = _bookings.where((b) => b.status.toLowerCase() == 'completed').length;
    final pendingCount = _bookings.where((b) => b.status.toLowerCase() == 'pending').length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('EmuLearn', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryBlue, fontSize: 24)),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          const NotificationBell(color: Color(0xFF1E293B)),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Message
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back, ${user?.name ?? 'Student'}! 👋', 
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          const Text('Ready to level up your language skills today?', 
                            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 15)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Student Real-World Info
                    _buildLevelAndInterestsRow(user?.level, List<String>.from(user?.interests ?? [])),
                    
                    const SizedBox(height: 32),
                    // Stats Row
                    _buildStatsRow(completedCount, pendingCount, upcoming.length),
                    
                    const SizedBox(height: 32),
                    
                    // Quick Actions (Styled like teaching topics in 5.png)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          TextButton(
                            onPressed: () {}, 
                            child: const Text('Edit', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w600))
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActionsGrid(),
                    
                    const Divider(height: 48, thickness: 1, color: Color(0xFFF1F5F9)),
                    
                    // Upcoming Schedule (Calendar style from 5.png)
                    _buildUpcomingSchedule(upcoming),
                    
                    const Divider(height: 48, thickness: 1, color: Color(0xFFF1F5F9)),
                    
                    // Recommended Teachers (Styled like the profile info in 5.png)
                    _buildRecommendedTeachersSection(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              
              // Bottom Action Button (Fixed like in 5.png)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: EduPrimaryButton(
                  label: 'Find New Teacher',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherListScreen())),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildLevelAndInterestsRow(String? level, List<String> interests) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryTeal.withOpacity(0.05), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    level?.toUpperCase() ?? 'BEGINNER',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Proficiency Level', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            if (interests.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: interests.take(3).map((interest) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(interest, style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w700)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(int completed, int pending, int upcoming) {
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
            _buildStatItem('SESSIONS', '$completed'),
            Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
            _buildStatItem('UPCOMING', '$upcoming'),
            Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
            _buildStatItem('PENDING', '$pending'),
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

  Widget _buildQuickActionsGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildActionChip(Icons.calendar_month_rounded, 'My Sessions', const Color(0xFFE2F2EF), AppTheme.primaryTeal),
          const SizedBox(width: 12),
          _buildActionChip(Icons.auto_stories_rounded, 'Learning Topics', const Color(0xFFEEF2FF), Colors.indigo),
          const SizedBox(width: 12),
          _buildActionChip(Icons.history_rounded, 'Past Requests', const Color(0xFFFFF7ED), Colors.orange),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, Color bg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: iconColor, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildUpcomingSchedule(List<Booking> upcoming) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Upcoming Schedule',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Today', // More dynamic than March 2026
                style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
              ),
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
                    Text(dayName, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11)),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: upcoming.map((b) => ModernCard(
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
                          Text(b.topic, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('with ${b.teacherName} • ${b.scheduledTime.split(' ').last}', 
                            style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecommendedTeachersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('Top Recommended', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _recommendedTeachers.length,
            itemBuilder: (context, index) {
              final t = _recommendedTeachers[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16, bottom: 8),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/teacher-profile', arguments: t),
                  child: ModernCard(
                    padding: const EdgeInsets.all(20),
                    radius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ModernAvatar(
                              imageUrl: t.profileImageUrl,
                              fallbackText: t.name,
                              radius: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                                  const SizedBox(height: 2),
                                  Text(t.title.isNotEmpty ? t.title : 'General English Teacher', 
                                    style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.w600, fontSize: 13),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                                const SizedBox(width: 4),
                                Text('${t.rating}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              ],
                            ),
                            Text(t.location.isNotEmpty ? t.location : 'Remote', 
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const StatusBadge(label: 'VERIFIED EXPERT', color: AppTheme.primaryTeal),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
