const express = require('express');
const router = express.Router();
const sessionController = require('../controllers/sessionController');

router.post('/', sessionController.createSessionRequest);
router.get('/teacher/:teacherId', sessionController.getSessionsForTeacher);
router.patch('/:id/status', sessionController.updateSessionStatus);

module.exports = router;
