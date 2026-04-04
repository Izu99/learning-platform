const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const auth = require('../middleware/auth');

router.post('/', auth, bookingController.createBooking);
router.get('/student/:studentId', auth, bookingController.getBookingsForStudent);
router.get('/teacher/:teacherId', auth, bookingController.getBookingsForTeacher);
router.patch('/:id/status', auth, bookingController.updateBookingStatus);

module.exports = router;
