# Architectural Plan: Full API Test System

## 1. Overview
The test system will use a consistent mocking strategy with `mockingoose` and `supertest`. Each domain-specific test file will handle its own tokens and mock data, sharing a set of common "Valid ObjectIds" to maintain consistency.

## 2. Shared Test Data (Constants)
- **ADMIN_ID**: `507f1f77bcf86cd799439016`
- **TEACHER_USER_ID**: `507f1f77bcf86cd799439014`
- **STUDENT_USER_ID**: `507f1f77bcf86cd799439015`
- **TEACHER_PROFILE_ID**: `507f1f77bcf86cd799439011`
- **BOOKING_ID**: `507f1f77bcf86cd799439017`
- **SESSION_ID**: `507f1f77bcf86cd799439018`

## 3. API Contracts & Test Cases

### 3.1 Authentication (`/api/auth`)
- `POST /register`: 
    - Success: 201 Created + Token.
    - Failure: 400 (User already exists).
- `POST /login`:
    - Success: 200 OK + Token.
    - Failure: 401 (Invalid credentials).
- `POST /preferences`:
    - Success: 200 OK (Auth required).

### 3.2 Teachers (`/api/teachers`)
- `GET /`: List all teachers (200 OK).
- `GET /profile/:userId`: Fetch profile (200 OK / 404).
- `POST /profile`: Create/Update profile (200 OK / 401).
- `GET /:teacherId/available-slots`: (200 OK).

### 3.3 Bookings (`/api/bookings`)
- `POST /`: Create booking (201 Created / 401).
- `GET /student/:studentId`: (200 OK).
- `GET /teacher/:teacherId`: (200 OK).
- `PATCH /:id/status`: Update status (200 OK / 403).

### 3.4 Sessions (`/api/sessions`)
- `POST /`: Create session request (201 Created).
- `GET /teacher/:teacherId`: (200 OK).
- `PATCH /:id/status`: Update status (200 OK).

## 4. Execution Plan

### Phase 1: Authentication Tests
- **Step**: Implement `server/test/auth.test.js`
  - Output: `server/test/auth.test.js`
  - Validation: `npm test test/auth.test.js`
  - Risk: Bcrypt hashing might need careful mocking if not using `comparePassword` correctly.

### Phase 2: Teacher Profile Tests
- **Step**: Implement `server/test/teacher.test.js`
  - Output: `server/test/teacher.test.js`
  - Validation: `npm test test/teacher.test.js`
  - Risk: Multipart image upload mocking.

### Phase 3: Booking & Session Tests
- **Step**: Implement `server/test/booking.test.js` and `server/test/session.test.js`
  - Output: Two new test files.
  - Validation: `npm test test/booking.test.js test/session.test.js`
  - Risk: Relationship between User and TeacherProfile might be complex to mock.

### Phase 4: Final Consolidation
- **Step**: Run full suite and generate report.
  - Output: Updated `.agent-runs/07-integrator.md`.
  - Validation: `npm test` (all 5 files passing).

## 5. Security & Robustness
- **Auth**: Every protected route must have a 401 Unauthorized test case.
- **RBAC**: Routes restricted to 'admin' or 'teacher' must have 403 Forbidden test cases for 'student'.
- **Mocking**: `mockingoose.resetAll()` in `afterEach` is mandatory.
