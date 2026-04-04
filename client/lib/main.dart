import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/auth_provider.dart';
import 'core/notification_provider.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/teacher/admin_teacher_list_screen.dart';
import 'screens/admin/student/admin_student_list_screen.dart';
import 'screens/admin/teacher_approval_screen.dart';
import 'screens/teacher_profile/teacher_profile_screen.dart';
import 'screens/student_profile/student_profile_screen.dart';
import 'models/teacher_model.dart';
import 'models/user_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmuLearn Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Shared logic for admin route protection can be added here
        switch (settings.name) {
          case '/admin/dashboard':
            return MaterialPageRoute(builder: (context) => const AdminDashboardScreen());
          case '/admin/teachers':
            return MaterialPageRoute(builder: (context) => const AdminTeacherListScreen());
          case '/admin/students':
            return MaterialPageRoute(builder: (context) => const AdminStudentListScreen());
          case '/admin/teacher-approval':
          case '/teacher-profile':
            final teacher = settings.arguments as Teacher;
            return MaterialPageRoute(
              builder: (context) => TeacherProfileScreen(teacher: teacher),
            );
          case '/student-profile':
            final user = settings.arguments as User;
            return MaterialPageRoute(
              builder: (context) => StudentProfileScreen(user: user),
            );
          case '/notifications':
            return MaterialPageRoute(builder: (context) => const NotificationsScreen());
          case '/':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          default:
            return MaterialPageRoute(builder: (context) => const LoginScreen());
        }
      },
    );
  }
}
