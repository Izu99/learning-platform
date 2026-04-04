
## Delivery Plan

### Phase 1: Planning and API Design (Delegated to Planner Agent)

*   **Planner Task 1: Database Schema Updates for Teacher Status**
    *   **Objective:** Define necessary schema changes to store teacher registration status (e.g., `pending`, `approved`, `rejected`).
    *   **Expected Output:** Updated database schema definition (e.g., `server/src/models/teacher_model.js` updates).
    *   **Validation Method:** Review `02-planner.md` for schema changes.
    *   **Rollback Plan:** Revert schema changes.

*   **Planner Task 2: API Endpoints for Admin Teacher Management**
    *   **Objective:** Design API endpoints for:
        *   Retrieving a list of pending teachers.
        *   Retrieving a single teacher's details (for admin review).
        *   Updating a teacher's status (approve/reject).
        *   Retrieving dashboard metrics (total teachers, total students, pending teachers).
    *   **Expected Output:** API contract definitions (endpoints, request/response bodies, authentication requirements) in `02-planner.md`.
    *   **Validation Method:** Review `02-planner.md` for API contract completeness.
    *   **Rollback Plan:** Revert API contract changes.

*   **Planner Task 3: API Endpoint for Student Details (for Teacher Request Page)**
    *   **Objective:** Design an API endpoint to fetch student details, including "instagram profile" and "register" information, given a student ID.
    *   **Expected Output:** API contract definition in `02-planner.md`.
    *   **Validation Method:** Review `02-planner.md` for API contract completeness.
    *   **Rollback Plan:** Revert API contract changes.

### Phase 2: Backend Implementation (Delegated to Backend Developer Agent)

*   **Backend Task 1: Implement Database Schema Updates**
    *   **Objective:** Apply the defined database schema changes (e.g., add `status` field to teacher model).
    *   **Expected Output:** Modified database model files (e.g., `server/src/models/teacher_model.js`).
    *   **Validation Method:** Manual database inspection or unit tests for model.
    *   **Rollback Plan:** Database backup/restore or revert migration.

*   **Backend Task 2: Implement Admin Teacher Management Endpoints**
    *   **Objective:** Implement the API endpoints for listing, viewing, and updating teacher statuses.
    *   **Expected Output:** New/modified controller and route files (e.g., `server/src/routes/admin.js`, `server/src/controllers/admin_controller.js`).
    *   **Validation Method:** Postman/cURL tests against the new endpoints.
    *   **Rollback Plan:** Revert file changes.

*   **Backend Task 3: Implement Dashboard Metrics Endpoint**
    *   **Objective:** Implement the API endpoint to retrieve total teachers, students, and pending teachers counts.
    *   **Expected Output:** Modified controller/route files.
    *   **Validation Method:** Postman/cURL tests.
    *   **Rollback Plan:** Revert file changes.

*   **Backend Task 4: Implement Student Details Endpoint**
    *   **Objective:** Implement the API endpoint to fetch student details for the teacher request page.
    *   **Expected Output:** Modified controller/route files.
    *   **Validation Method:** Postman/cURL tests.
    *   **Rollback Plan:** Revert file changes.

### Phase 3: Frontend Implementation (Delegated to Frontend Developer Agent)

*   **Frontend Task 1: Implement Admin Login/Authentication (if needed)**
    *   **Objective:** Ensure only authorized admins can access the admin routes.
    *   **Expected Output:** Modified `client/lib/core/auth_provider.dart` and routing.
    *   **Validation Method:** Manual login tests with admin/non-admin accounts.
    *   **Rollback Plan:** Revert file changes.

*   **Frontend Task 2: Implement Admin Teacher Approval UI**
    *   **Objective:** Create the Flutter UI for listing pending teachers, viewing their details, and accepting/rejecting them.
    *   **Expected Output:** New Flutter screen files (e.g., `client/lib/screens/admin/teacher_approval_screen.dart`).
    *   **Validation Method:** Manual UI testing.
    *   **Rollback Plan:** Remove new files.

*   **Frontend Task 3: Implement Admin Dashboard UI**
    *   **Objective:** Create the Flutter UI for displaying total teachers, students, and other metrics.
    *   **Expected Output:** New Flutter screen files (e.g., `client/lib/screens/admin/dashboard_screen.dart`).
    *   **Validation Method:** Manual UI testing.
    *   **Rollback Plan:** Remove new files.

*   **Frontend Task 4: Modify Teacher Request Page for Student Details Pop-up**
    *   **Objective:** Integrate the student detail pop-up into the existing teacher request page.
    *   **Expected Output:** Modified Flutter widget/screen files (e.g., `client/lib/screens/dashboard/request_page.dart` or similar).
    *   **Validation Method:** Manual UI testing.
    *   **Rollback Plan:** Revert file changes.

### Phase 4: Testing (Delegated to Test Agent)

*   **Test Task 1: Backend Unit/Integration Tests**
    *   **Objective:** Write tests for the new admin API endpoints and data models.
    *   **Expected Output:** New test files (e.g., `server/test/admin_api.test.js`).
    *   **Validation Method:** Run tests (`npm test` or similar).
    *   **Rollback Plan:** Revert test file changes.

*   **Test Task 2: Frontend Widget/Integration Tests**
    *   **Objective:** Write tests for the new admin UI components and the student detail pop-up.
    *   **Expected Output:** New test files (e.g., `client/test/admin_dashboard_test.dart`).
    *   **Validation Method:** Run tests (`flutter test`).
    *   **Rollback Plan:** Revert test file changes.

### Phase 5: Integration and Validation (Delegated to Integrator Agent)

*   **Integrator Task 1: End-to-End Integration Testing**
    *   **Objective:** Verify that frontend and backend components work together seamlessly for both admin and teacher features.
    *   **Expected Output:** `07-integrator.md` report.
    *   **Validation Method:** Manual end-to-end testing of all new features.
    *   **Rollback Plan:** Revert all changes if major issues.
