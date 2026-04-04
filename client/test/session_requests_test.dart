import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/core/auth_provider.dart';
import 'package:learning_platform/models/booking_model.dart';
import 'package:learning_platform/models/user_model.dart';
import 'package:learning_platform/screens/dashboard/session_requests_screen.dart';
import 'package:learning_platform/widgets/modern_avatar.dart'; // Assuming ModernAvatar is used in the modal

// Mock classes for ApiService and AuthProvider
class MockApiService extends Mock implements ApiService {}
class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late MockApiService mockApiService;
  late MockAuthProvider mockAuthProvider;

  // Dummy user data for testing
  final dummyStudent = User(
    id: 'student123',
    name: 'John Doe',
    email: 'john.doe@example.com',
    role: 'student',
    profileImageUrl: 'http://example.com/johndoe.jpg',
    level: 'Beginner',
    interests: ['Math', 'Science'],
    instagramHandle: '@johndoe_learns',
    registrationDate: '2023-01-15',
  );

  // Dummy booking data for testing
  final dummyBooking = Booking(
    id: 'booking1',
    studentId: dummyStudent.id,
    studentName: dummyStudent.name,
    studentProfileImageUrl: dummyStudent.profileImageUrl,
    studentLevel: dummyStudent.level,
    teacherId: 'teacher456',
    teacherName: 'Jane Smith',
    topic: 'Algebra',
    scheduledTime: '2024-10-26, 10:00 AM',
    status: 'Pending',
    notes: 'Needs help with equations.',
  );

  setUp(() {
    mockApiService = MockApiService();
    mockAuthProvider = MockAuthProvider();

    // Mock current user in AuthProvider
    when(mockAuthProvider.currentUser).thenReturn(User(
      id: 'teacher456',
      name: 'Jane Smith',
      email: 'jane.smith@example.com',
      role: 'teacher',
    ));

    // Mock initial API call for fetching requests
    when(mockApiService.get('/bookings/teacher/teacher456')).thenAnswer(
      (_) async => [dummyBooking.toJson()],
    );
  });

  // Helper function to pump the widget for testing
  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApiService),
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
      ],
      child: const MaterialApp(
        home: SessionRequestsScreen(),
      ),
    );
  }

  group('SessionRequestsScreen Student Details Pop-up Tests', () {
    testWidgets('Student detail pop-up appears on tapping "Student Profile Summary"', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle(); // Settle initial data fetching

      // Mock the student details API call for when the pop-up is triggered
      when(mockApiService.get('/admin/students/${dummyStudent.id}'))
          .thenAnswer((_) async => dummyStudent.toJson());

      // Tap on the GestureDetector wrapping the student profile summary
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle(); // Settle the modal opening and data fetching

      // Verify that the BottomSheet appears
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget); // Verify student name is visible
      expect(find.text('Beginner'), findsOneWidget); // Verify student level is visible
      expect(find.text('Math'), findsOneWidget); // Verify student interest is visible
      expect(find.text('@johndoe_learns'), findsOneWidget); // Verify instagram handle
      expect(find.text('Registered: 2023-01-15'), findsOneWidget); // Verify registration date
      expect(find.text('Needs help with equations.'), findsOneWidget); // Verify notes

      // Verify the close button is present
      expect(find.widgetWithText(ElevatedButton, 'Close Detail'), findsOneWidget);
    });

    testWidgets('Student detail pop-up appears on tapping "View Detail" button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      when(mockApiService.get('/admin/students/${dummyStudent.id}'))
          .thenAnswer((_) async => dummyStudent.toJson());

      // Tap on the "View Detail" TextButton
      await tester.tap(find.widgetWithText(TextButton, 'View Detail'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('Loading indicator is shown while fetching student details', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Mock the student details API call to be delayed
      when(mockApiService.get('/admin/students/${dummyStudent.id}'))
          .thenAnswer((_) async => Future.delayed(const Duration(seconds: 2), () => dummyStudent.toJson()));

      await tester.tap(find.byType(GestureDetector));
      await tester.pump(); // Pump once to trigger the FutureBuilder

      // Verify that CircularProgressIndicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('John Doe'), findsNothing); // Student details should not be visible yet

      await tester.pumpAndSettle(); // Wait for the Future to complete
      expect(find.text('John Doe'), findsOneWidget); // Now student details should be visible
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Error message is displayed if fetching student details fails', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Mock the student details API call to throw an error
      when(mockApiService.get('/admin/students/${dummyStudent.id}'))
          .thenThrow(Exception('Network Error'));

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle(); // Settle the modal opening and error display

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Failed to load student details: Exception: Network Error'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Closing the student detail pop-up', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      when(mockApiService.get('/admin/students/${dummyStudent.id}'))
          .thenAnswer((_) async => dummyStudent.toJson());

      // Open the pop-up
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // Tap the "Close Detail" button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Close Detail'));
      await tester.pumpAndSettle();

      // Verify the pop-up is no longer present
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('John Doe'), findsNothing);
    });

    testWidgets('Empty state for interests is handled', (tester) async {
      final studentWithNoInterests = User(
        id: 'student456',
        name: 'Jane Doe',
        email: 'jane.doe@example.com',
        role: 'student',
        profileImageUrl: 'http://example.com/janedoe.jpg',
        level: 'Advanced',
        interests: [], // Empty interests
      );
      final bookingForJane = dummyBooking.copyWith(
        id: 'booking2',
        studentId: studentWithNoInterests.id,
        studentName: studentWithNoInterests.name,
        studentProfileImageUrl: studentWithNoInterests.profileImageUrl,
        studentLevel: studentWithNoInterests.level,
      );

      // Update mock for initial fetch
      when(mockApiService.get('/bookings/teacher/teacher456')).thenAnswer(
        (_) async => [bookingForJane.toJson()],
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      when(mockApiService.get('/admin/students/${studentWithNoInterests.id}'))
          .thenAnswer((_) async => studentWithNoInterests.toJson());

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('No specific interests listed.'), findsOneWidget);
      expect(find.text('Math'), findsNothing); // Should not find old interests
    });
  });
}

// Add copyWith to Booking model for easier testing modifications
extension BookingCopyWith on Booking {
  Booking copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentProfileImageUrl,
    String? studentLevel,
    String? teacherId,
    String? teacherName,
    String? topic,
    String? scheduledTime,
    String? status,
    String? notes,
    String? suggestedTime,
  }) {
    return Booking(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentProfileImageUrl: studentProfileImageUrl ?? this.studentProfileImageUrl,
      studentLevel: studentLevel ?? this.studentLevel,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      topic: topic ?? this.topic,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      suggestedTime: suggestedTime ?? this.suggestedTime,
    );
  }
}
