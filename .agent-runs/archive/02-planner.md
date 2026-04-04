# Planner Plan: Teacher Profile UI

## Objective
Design the Flutter widget structure and data models for the "Teacher Profile" screen based on the Tech Lead's requirements (`.agent-runs/01-techlead.md`) and the visual reference (`client/ui/5.png`).

## 1. Data Models
We need a `TeacherProfile` model to hold the data displayed on the screen.

```dart
// lib/models/teacher_profile.dart

class TeacherProfile {
  final String id;
  final String name;
  final String title;
  final String imageUrl;
  final bool isOnline;
  final double rating;
  final int reviewCount;
  final int experienceYears;
  final int studentCount;
  final double hourlyRate;
  final List<String> certifications;
  final String aboutMe;
  final List<String> teachingTopics;
  final List<DateTime> availableDates;
  final List<String> availableTimeSlots; // e.g., "09:00 AM"

  TeacherProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.imageUrl,
    required this.isOnline,
    required this.rating,
    required this.reviewCount,
    required this.experienceYears,
    required this.studentCount,
    required this.hourlyRate,
    required this.certifications,
    required this.aboutMe,
    required this.teachingTopics,
    required this.availableDates,
    required this.availableTimeSlots,
  });
}
```

## 2. Widget Structure
The screen will be composed of several specialized widgets to maintain clean code and reusability.

*   `TeacherProfileScreen`: The main scaffold.
    *   `SliverAppBar` or standard `AppBar`: For the header.
    *   `SingleChildScrollView`: For the scrollable content.
        *   `ProfileHeader`: Image, name, title, rating.
        *   `StatsRow`: Experience, Students, Rate.
        *   `CertificationsList`: Horizontal list of badges.
        *   `SectionTitle`: Reusable widget for section headers ("About Me", "Teaching Topics", etc.).
        *   `Text`: For "About Me" content.
        *   `Wrap`: For "Teaching Topics" chips.
        *   `AvailabilityCalendar`: Horizontal date picker.
        *   `TimeSlotGrid`: Grid/Wrap of time slots.
        *   `SessionTopicSelector`: List of selectable topics.
        *   `CustomRequestInput`: Text field.
    *   `BottomBookingBar`: Sticky bottom container with the "Send Booking Request" button.

## 3. Theme & Styling
*   **Colors:** Use the existing app theme (`Theme.of(context)`).
    *   Primary Color: Dark Green/Teal (from image button).
    *   Secondary Color: Light Green/Teal (for chip backgrounds).
    *   Text Colors: Dark grey for headings, lighter grey for body text.
*   **Typography:** Use `TextTheme` styles (e.g., `titleLarge`, `bodyMedium`).
*   **Spacing:** Consistent padding (e.g., `16.0` or `20.0`) between sections.

## 4. Execution Plan
1.  **Models:** Create `lib/models/teacher_profile.dart`.
2.  **Widgets:** Create reusable widgets in `lib/screens/teacher_profile/widgets/`.
    *   `profile_header.dart`
    *   `stats_row.dart`
    *   `certifications_list.dart`
    *   `availability_calendar.dart`
    *   `time_slot_grid.dart`
    *   `session_topic_selector.dart`
3.  **Screen:** Assemble `TeacherProfileScreen` in `lib/screens/teacher_profile/teacher_profile_screen.dart` using the widgets.
4.  **Mock Data:** Create a static instance of `TeacherProfile` to populate the UI for the demo.
5.  **Route:** Register the screen in `lib/main.dart` or the router configuration.

## 5. Risks & Mitigations
*   **Asset Availability:** Use `Icons.person` or a network placeholder if local assets are missing.
*   **Screen Overflow:** Ensure `SingleChildScrollView` wraps the main content to avoid overflow errors on smaller screens.
*   **State Management:** For this UI prototype, use `StatefulWidget` to handle local state (selected date, time slot, topic).

## 6. Validation
*   Run the app and navigate to the "Teacher Profile" screen.
*   Verify all sections are visible and match the design.
*   Check interactivity (scrolling, selecting chips).

---

# Planner Task: Teacher and Admin Management

## Planner Task 1: Database Schema Updates for Teacher Status

*   **Objective:** Define necessary schema changes to store teacher registration status (e.g., `pending`, `approved`, `rejected`).
*   **File to update:** `server/src/models/teacher_model.js`
*   **Change:** Add a `status` field to the `Teacher` schema.
    *   **Type:** `String`
    *   **Enum:** `['pending', 'approved', 'rejected']`
    *   **Default:** `pending`
*   **Validation Method:** Review `02-planner.md` for schema changes.
*   **Rollback Plan:** Revert schema changes.

## Planner Task 2: API Endpoints for Admin Teacher Management

*   **Objective:** Design API endpoints for admin teacher management.
*   **API Base Path:** `/api/v1/admin`
*   **Authentication:** Admin required for all endpoints in this section.

### Endpoint 1: Retrieve a list of pending teachers
*   **Method:** `GET`
*   **Path:** `/admin/teachers/pending`
*   **Query Parameters:**
    *   `limit`: (Optional) `Number`. Number of results to return. Default: 10.
    *   `offset`: (Optional) `Number`. Number of results to skip. Default: 0.
*   **Response (200 OK):**
    ```json
    {
        "success": true,
        "teachers": [
            {
                "_id": "teacherId1",
                "name": "Teacher One",
                "email": "teacher1@example.com",
                "status": "pending",
                "createdAt": "2023-01-01T12:00:00Z"
                // ... other relevant teacher details for admin overview
            }
        ],
        "total": 1,
        "limit": 10,
        "offset": 0
    }
    ```

### Endpoint 2: Retrieve a single teacher's details (for admin review)
*   **Method:** `GET`
*   **Path:** `/admin/teachers/:id`
*   **Path Parameters:**
    *   `id`: `String`. The ID of the teacher to retrieve.
*   **Response (200 OK):**
    ```json
    {
        "success": true,
        "teacher": {
            "_id": "teacherId1",
            "name": "Teacher One",
            "email": "teacher1@example.com",
            "status": "pending",
            "bio": "Experienced math teacher.",
            "certifications": ["Certification A", "Certification B"],
            "hourlyRate": 50,
            "contact": {
                "phone": "123-456-7890",
                "address": "123 Teaching Lane"
            }
            // ... all teacher details
        }
    }
    ```
*   **Response (404 Not Found):**
    ```json
    {
        "success": false,
        "message": "Teacher not found"
    }
    ```

### Endpoint 3: Update a teacher's status (approve/reject)
*   **Method:** `PUT`
*   **Path:** `/admin/teachers/:id/status`
*   **Path Parameters:**
    *   `id`: `String`. The ID of the teacher to update.
*   **Request Body:**
    ```json
    {
        "status": "approved" // Required. Enum: ["approved", "rejected"]
    }
    ```
*   **Response (200 OK):**
    ```json
    {
        "success": true,
        "message": "Teacher status updated successfully",
        "teacher": {
            "_id": "teacherId1",
            "status": "approved"
        }
    }
    ```
*   **Response (400 Bad Request):**
    ```json
    {
        "success": false,
        "message": "Invalid status provided"
    }
    ```
*   **Response (404 Not Found):**
    ```json
    {
        "success": false,
        "message": "Teacher not found"
    }
    ```

### Endpoint 4: Retrieve dashboard metrics
*   **Method:** `GET`
*   **Path:** `/admin/dashboard/metrics`
*   **Response (200 OK):
    ```json
    {
        "success": true,
        "metrics": {
            "totalTeachers": 100,
            "totalStudents": 500,
            "pendingTeachers": 5,
            "approvedTeachers": 95,
            "rejectedTeachers": 2
        }
    }
    ```
*   **Validation Method:** Review `02-planner.md` for API contract completeness.
*   **Rollback Plan:** Revert API contract changes.

## Planner Task 3: API Endpoint for Student Details (for Teacher Request Page)

*   **Objective:** Design an API endpoint to fetch student details, including "instagram profile" and "register" information, given a student ID.
*   **API Base Path:** `/api/v1`
*   **Authentication:** Authenticated user (teacher or admin) required.

### Endpoint: Get student details by ID
*   **Method:** `GET`
*   **Path:** `/students/:id`
*   **Path Parameters:**
    *   `id`: `String`. The ID of the student to retrieve.
*   **Response (200 OK):**
    ```json
    {
        "success": true,
        "student": {
            "_id": "studentId1",
            "name": "Student One",
            "email": "student1@example.com",
            "instagramProfile": "https://instagram.com/studentone",
            "registrationDate": "2023-01-15T10:00:00Z",
            // ... other student details relevant for a teacher (e.g., past sessions, interests)
        }
    }
    ```
*   **Response (404 Not Found):**
    ```json
    {
        "success": false,
        "message": "Student not found"
    }
    ```
*   **Validation Method:** Review `02-planner.md` for API contract completeness.
*   **Rollback Plan:** Revert API contract changes.