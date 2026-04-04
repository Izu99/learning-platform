import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/core/auth_provider.dart';
import 'package:learning_platform/models/teacher_model.dart';
import 'package:learning_platform/models/user_model.dart';
import 'package:learning_platform/screens/admin/teacher_approval_screen.dart';

// Manual Mock ApiService to control its responses
class MockApiService {
  static Future<dynamic> Function(String endpoint)? getMock;
  static Future<dynamic> Function(String endpoint, Map<String, dynamic> data)? putMock;

  static Future<dynamic> get(String endpoint) {
    if (getMock != null) {
      return getMock!(endpoint);
    }
    throw UnimplementedError('ApiService().get not mocked for endpoint: $endpoint');
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) {
    if (putMock != null) {
      return putMock!(endpoint, data);
    }
    throw UnimplementedError('ApiService().put not mocked for endpoint: $endpoint with data: $data');
  }
}

// Manual Mock AuthProvider to simulate an authenticated admin user
class MockAuthProvider extends AuthProvider {
  @override
  User? get currentUser => User(
    id: 'adminId',
    name: 'Admin User',
    email: 'admin@example.com',
    role: 'admin',
  );

  @override
  bool get isAuthenticated => true;
}

void main() {
  group('TeacherApprovalScreen Tests', () {
    // Helper function to create a dummy Teacher object with required fields
    Teacher createDummyTeacher({
      required String id,
      required String name,
      String email = 'test@example.com',
      String status = 'pending',
    }) {
      return Teacher(
        id: id,
        name: name,
        email: email,
        status: status,
        title: 'Dummy Title',
        location: 'Dummy Location',
        rating: 4.5,
        studentsCount: 10,
        lessonsCount: 5,
        hoursCount: 20,
        experienceYears: 2,
        isVerified: true,
        isOnline: true,
        about: 'Dummy about text',
        tags: ['Math', 'Science'],
        availability: [],
        timeSlots: [],
        sessionTopics: ['Algebra'],
      );
    }

    setUp(() {
      // Reset mocks before each test
      MockApiService.getMock = null;
      MockApiService.putMock = null;
    });

    testWidgets('displays CircularProgressIndicator while loading', (tester) async {
      // Simulate loading state by delaying the API response
      MockApiService.getMock = (endpoint) async {
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        return [];
      };

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
          ],
          child: MaterialApp(
            home: const TeacherApprovalScreen(),
            scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(), // Needed for SnackBar
          ),
        ),
      );

      // Verify CircularProgressIndicator is shown initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No pending teachers.'), findsNothing);
      expect(find.textContaining('Failed to load pending teachers:'), findsNothing);

      await tester.pumpAndSettle(); // Wait for the Future to complete and UI to rebuild

      // After loading, if the response is empty, it should show "No pending teachers."
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No pending teachers.'), findsOneWidget);
    });

    testWidgets('displays pending teachers', (tester) async {
      final pendingTeachers = [
        createDummyTeacher(id: '1', name: 'John Doe', email: 'john@example.com'),
        createDummyTeacher(id: '2', name: 'Jane Smith', email: 'jane@example.com'),
      ];

      MockApiService.getMock = (endpoint) async {
        return pendingTeachers.map((e) => e.toJson()).toList();
      };

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
          ],
          child: MaterialApp(
            home: const TeacherApprovalScreen(),
            scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          ),
        ),
      );

      await tester.pumpAndSettle(); // Wait for data to load and widget to rebuild

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
      expect(find.text('Status: pending'), findsNWidgets(2));
    });

    testWidgets('displays "No pending teachers" when list is empty', (tester) async {
      MockApiService.getMock = (endpoint) async {
        return [];
      };

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
          ],
          child: MaterialApp(
            home: const TeacherApprovalScreen(),
            scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          ),
        ),
      );

      await tester.pumpAndSettle(); // Wait for data to load and widget to rebuild

      expect(find.text('No pending teachers.'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('approves a teacher and refreshes list', (tester) async {
      final initialPendingTeachers = [
        createDummyTeacher(id: '1', name: 'John Doe', email: 'john@example.com'),
      ];
      final afterApprovalPendingTeachers = <Teacher>[]; // Empty list after approval

      // Sequence of GET mock responses: first returns pending, then empty
      int getCallCount = 0;
      MockApiService.getMock = (endpoint) async {
        getCallCount++;
        if (getCallCount == 1) {
          return initialPendingTeachers.map((e) => e.toJson()).toList();
        } else {
          return afterApprovalPendingTeachers.map((e) => e.toJson()).toList();
        }
      };

      // Mock PUT call for approval
      MockApiService.putMock = (endpoint, data) async {
        expect(endpoint, '/admin/teachers/1/status');
        expect(data['status'], 'approved');
        return {'message': 'Teacher approved'};
      };

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
          ],
          child: MaterialApp(
            home: const TeacherApprovalScreen(),
            scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          ),
        ),
      );

      await tester.pumpAndSettle(); // Load initial teachers

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Status: pending'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Approve'));
      await tester.pump(); // Trigger rebuilding for SnackBar and async operations

      // Expect SnackBar to appear
      expect(find.text('Teacher approved successfully!'), findsOneWidget);

      await tester.pumpAndSettle(); // Wait for SnackBar to disappear and list to refresh

      expect(find.text('John Doe'), findsNothing);
      expect(find.text('No pending teachers.'), findsOneWidget);
    });

    testWidgets('rejects a teacher and refreshes list', (tester) async {
      final initialPendingTeachers = [
        createDummyTeacher(id: '1', name: 'Alice', email: 'alice@example.com'),
      ];
      final afterRejectionPendingTeachers = <Teacher>[]; // Empty list after rejection

      int getCallCount = 0;
      MockApiService.getMock = (endpoint) async {
        getCallCount++;
        if (getCallCount == 1) {
          return initialPendingTeachers.map((e) => e.toJson()).toList();
        } else {
          return afterRejectionPendingTeachers.map((e) => e.toJson()).toList();
        }
      };

      MockApiService.putMock = (endpoint, data) async {
        expect(endpoint, '/admin/teachers/1/status');
        expect(data['status'], 'rejected');
        return {'message': 'Teacher rejected'};
      };

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
          ],
          child: MaterialApp(
            home: const TeacherApprovalScreen(),
            scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Status: pending'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
      await tester.pump();

      expect(find.text('Teacher rejected successfully!'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsNothing);
      expect(find.text('No pending teachers.'), findsOneWidget);
    });

    testWidgets('displays error message when fetching fails', (tester) async {
      MockApiService.getMock = (endpoint) async {
        throw Exception('Failed to connect to server');
      };

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
          ],
          child: MaterialApp(
            home: const TeacherApprovalScreen(),
            scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
          ),
        ),
      );

      await tester.pumpAndSettle(); // Wait for the error to propagate and widget to rebuild

      expect(find.textContaining('Failed to load pending teachers: Exception: Failed to connect to server'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No pending teachers.'), findsNothing);
    });
  });
}
