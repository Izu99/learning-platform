import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'teacher_dashboard.dart';
import 'session_requests_screen.dart';
import 'schedule_management_screen.dart';
import 'profile_management_screen.dart';

class TeacherNavigationContainer extends StatefulWidget {
  const TeacherNavigationContainer({super.key});

  @override
  State<TeacherNavigationContainer> createState() => _TeacherNavigationContainerState();
}

class _TeacherNavigationContainerState extends State<TeacherNavigationContainer> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TeacherDashboard(),
    const SessionRequestsScreen(),
    const ScheduleManagementScreen(),
    const ProfileManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
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
              onTap: (index) => setState(() => _selectedIndex = index),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primaryTeal,
              unselectedItemColor: AppTheme.textMuted,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.mail_outline_rounded), label: 'Requests'),
                BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Schedule'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
