// client/test/admin_dashboard_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/core/auth_provider.dart';
import 'package:learning_platform/models/user_model.dart';
import 'package:learning_platform/screens/admin/admin_dashboard_screen.dart';

// Mock classes using Mockito
// This generated file is for use with the Mockito package.
// Whenever you change any of the methods below, a new MockApiService file
// is generated and will be used when tests are run.
// Please check 'pubspec.yaml' for required dependencies such as 'mockito'.
class MockApiService extends Mock implements ApiService {}
class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late MockApiService mockApiService;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockApiService = MockApiService();
    mockAuthProvider = MockAuthProvider();

    // Default mock responses for ApiService
    when(mockApiService.fetchDashboardMetrics()).thenAnswer((_) async => {
          'totalUsers': 100,
          'totalTeachers': 20,
          'totalSessions': 50,
          'totalBookings': 75,
        });

    // Default mock for AuthProvider.currentUser
    when(mockAuthProvider.currentUser).thenReturn(User(id: 'adminId', name: 'Admin', email: 'admin@example.com', role: 'admin'));
    when(mockAuthProvider.isAdmin).thenReturn(true); // Assuming isAdmin getter exists
  });

  Widget createAdminDashboardScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        // ApiService is typically provided as a simple Provider if its state
        // doesn't change and doesn't need to notify listeners.
        // If ApiService itself is a ChangeNotifier, it should be ChangeNotifierProvider.
        Provider<ApiService>.value(value: mockApiService),
      ],
      child: MaterialApp(
        home: AdminDashboardScreen(),
      ),
    );
  }

  group('AdminDashboardScreen Tests', () {
    testWidgets('displays loading indicator initially', (WidgetTester tester) async {
      // Simulate a delay in fetching data to show the loading indicator
      when(mockApiService.fetchDashboardMetrics()).thenAnswer(
        (_) => Future.delayed(const Duration(seconds: 2), () async => {
          'totalUsers': 100,
          'totalTeachers': 20,
          'totalSessions': 50,
          'totalBookings': 75,
        }),
      );

      await tester.pumpWidget(createAdminDashboardScreen());

      // Verify that a loading indicator is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading metrics...'), findsOneWidget); // Assuming a loading text
    });

    testWidgets('displays dashboard metrics correctly after fetching data', (WidgetTester tester) async {
      await tester.pumpWidget(createAdminDashboardScreen());

      // Wait for the Future to complete and the UI to rebuild
      await tester.pumpAndSettle();

      // Verify that the metrics are displayed
      expect(find.text('Total Users: 100'), findsOneWidget);
      expect(find.text('Total Teachers: 20'), findsOneWidget);
      expect(find.text('Total Sessions: 50'), findsOneWidget);
      expect(find.text('Total Bookings: 75'), findsOneWidget);

      // Verify that the loading indicator is no longer present
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Loading metrics...'), findsNothing);
    });

    testWidgets('displays error message if data fetching fails', (WidgetTester tester) async {
      when(mockApiService.fetchDashboardMetrics()).thenThrow(Exception('Failed to load dashboard data'));

      await tester.pumpWidget(createAdminDashboardScreen());
      await tester.pumpAndSettle();

      // Verify that an error message is displayed
      expect(find.text('Error: Exception: Failed to load dashboard data'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('displays proper title for Admin Dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(createAdminDashboardScreen());
      await tester.pumpAndSettle();

      // Assuming the AppBar has a title 'Admin Dashboard'
      expect(find.text('Admin Dashboard'), findsOneWidget);
    });

    // Additional test for ensuring proper layout (e.g. key widgets are present)
    testWidgets('dashboard structure contains expected widgets', (WidgetTester tester) async {
      await tester.pumpWidget(createAdminDashboardScreen());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget); // Assuming a ListView for scrollable content
      // Expect specific metric display widgets, assuming a generic Card or ListTile for each metric
      expect(find.byKey(const Key('totalUsersCard')), findsOneWidget);
      expect(find.byKey(const Key('totalTeachersCard')), findsOneWidget);
      expect(find.byKey(const Key('totalSessionsCard')), findsOneWidget);
      expect(find.byKey(const Key('totalBookingsCard')), findsOneWidget);
    });
  });
}
