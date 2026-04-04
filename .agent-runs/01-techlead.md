# Milestone: Full API Test System Implementation

## Objective
Implement a comprehensive, automated test suite for the EduLearn backend API. This suite will cover all critical domains: Authentication, Teacher Profiles, Bookings, Sessions, and Administration. The goal is to ensure API stability, correct business logic execution, and proper security enforcement (authentication/authorization).

## Non-goals
- UI testing (Flutter client).
- Performance/Load testing.
- External integration testing (e.g., actual database connection, unless using a local test DB; mocks are preferred for unit/integration tests).

## Constraints
- **Environment**: Node.js, Express, Mongoose.
- **Testing Tools**: Mocha, Chai (already upgraded/configured), Supertest, Mockingoose.
- **Security**: Must validate JWT authentication and role-based access control (RBAC).

## Acceptance Criteria
- [ ] 100% coverage of core API endpoints (Auth, Teachers, Bookings, Sessions, Admin).
- [ ] Positive tests (success scenarios) for every endpoint.
- [ ] Negative tests (failure scenarios: 400, 401, 403, 404) where applicable.
- [ ] Mocked database operations using `mockingoose` to avoid side effects and dependency on a running MongoDB instance.
- [ ] Tests must run via `npm test` in the `server` directory.

## Delivery Plan

### Planner Tasks
- **Task P1**: Define test data models and mock strategy for each domain (Auth, Teacher, Booking, Session).
- **Task P2**: Map out detailed test cases for each route identified in `app.js`.

### Backend/Test Tasks (Combined)
- **Task T1**: Implement Authentication API tests (`auth.test.js`).
    - Register, Login, Preference updates.
- **Task T2**: Implement Teacher API tests (`teacher.test.js`).
    - Listing, Profile management, Image upload (mocked), Slot availability.
- **Task T3**: Implement Booking API tests (`booking.test.js`).
    - Creation, Retrieval (Student/Teacher), Status updates.
- **Task T4**: Implement Session API tests (`session.test.js`).
    - Request creation, Retrieval, Status updates.
- **Task T5**: Consolidate and refine Admin API tests (`admin_api.test.js`).
    - Ensure alignment with other domain tests.

### Integration Tasks
- **Task I1**: Verify overall test suite execution.
- **Task I2**: Fix any naming inconsistencies between mocks and controllers.
- **Task I3**: Final report on test coverage and execution status.

## Delegation

- **Planner Agent**: Execute P1 and P2. Output: `.agent-runs/02-planner.md`.
- **Backend Developer / Test Agent**: Execute T1 to T5. Output: Updated `server/test/*.test.js` files.
- **Integrator Agent**: Execute I1 to I3. Output: `.agent-runs/07-integrator.md`.
