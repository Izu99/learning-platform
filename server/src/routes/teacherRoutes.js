const express = require('express');
const router = express.Router();
const teacherController = require('../controllers/teacherController');
const auth = require('../middleware/auth');
const { authenticateToken, authorizeRole } = require('../middleware/authMiddleware');
const upload = require('../middleware/upload');

router.get('/', teacherController.getAllTeachers);
router.get('/profile/:userId', teacherController.getTeacherProfile);
router.post('/profile', auth, teacherController.createOrUpdateProfile);

// Upload profile image (teachers or students)
router.post('/upload-image', authenticateToken, upload.single('image'), teacherController.uploadProfileImage);

// Available 40-minute slots for a teacher on a given date (Slicing logic)
router.get('/:teacherId/available-slots', teacherController.getAvailableSlots);

// Allow teachers to view basic student info (for booking context)
router.get('/student/:studentId', authenticateToken, authorizeRole(['teacher', 'admin']), teacherController.getStudentForTeacher);

module.exports = router;
