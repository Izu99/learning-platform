const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticateToken, authorizeRole } = require('../middleware/authMiddleware');

// Middleware to protect admin routes
router.use(authenticateToken);
router.use(authorizeRole(['admin']));

// Admin Teacher Management Endpoints
router.get('/teachers', adminController.listTeachers);
router.get('/teachers/:id', adminController.viewTeacher);
router.put('/teachers/:id/status', adminController.updateTeacherStatus);

// Dashboard Metrics Endpoint (Critical for Dashboard UI)
router.get('/dashboard/metrics', adminController.getDashboardMetrics);

// Student Details Endpoint (for teacher request page)
router.get('/students/:id', adminController.getStudentDetails);

// General User Management (Registration Lists)
router.get('/users', adminController.listUsers);

module.exports = router;
