import 'package:flutter/material.dart';
import 'package:learning_platform/core/app_theme.dart';
import 'package:learning_platform/screens/dashboard/student_dashboard.dart';
import 'package:learning_platform/screens/dashboard/teacher_list_screen.dart';
import 'package:learning_platform/screens/dashboard/my_sessions_screen.dart';
import 'package:learning_platform/screens/dashboard/my_requests_screen.dart';
import 'package:learning_platform/screens/dashboard/profile_management_screen.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/core/auth_provider.dart';

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _selectedIndex = 0;
  int _pendingRescheduleCount = 0;

  @override
  void initState() {
    super.initState();
    _checkRescheduleCount();
  }

  Future<void> _checkRescheduleCount() async {
    final studentId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (studentId == null) return;
    try {
      final response = await ApiService().get('/bookings/student/$studentId') as List;
      final count = response.where((b) => b['status']?.toString().toLowerCase() == 'rescheduled').length;
      if (mounted) setState(() => _pendingRescheduleCount = count);
    } catch (_) {}
  }

  final List<Widget> _screens = [
    const StudentDashboard(),
    const TeacherListScreen(),
    const MyRequestsScreen(),
    const MySessionsScreen(),
    const ProfileManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() => _selectedIndex = index);
                if (index == 2) _checkRescheduleCount(); // Refresh badge when Requests tab opened
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primaryBlue,
              unselectedItemColor: AppTheme.textMuted,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                const BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Explore'),
                BottomNavigationBarItem(
                  label: 'Requests',
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.mail_outline_rounded),
                      if (_pendingRescheduleCount > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: Text(
                              '$_pendingRescheduleCount',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Sessions'),
                const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
