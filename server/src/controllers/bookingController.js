const Booking = require('../models/Booking');
const crypto = require('crypto');
const { createInternalNotification } = require('./notificationController');
const User = require('../models/User');

exports.createBooking = async (req, res) => {
  try {
    const { teacherId, topic, scheduledTime, notes, studentId } = req.body;
    
    // VALIDATION: Prevent double-booking (Strict: Includes Pending and Accepted)
    const existing = await Booking.findOne({
      teacherId,
      scheduledTime,
      status: { $in: ['Pending', 'Accepted'] }
    });
    if (existing) {
      return res.status(400).json({ message: 'This slot is already reserved or booked.' });
    }

    const booking = new Booking({
      studentId: studentId || req.user.id,
      teacherId,
      topic,
      scheduledTime,
      notes
    });
    await booking.save();

    // NOTIFY TEACHER
    const student = await User.findById(booking.studentId);
    await createInternalNotification({
      recipient: booking.teacherId,
      sender: booking.studentId,
      title: 'New Booking Request',
      message: `${student?.name || 'A student'} has requested a session for ${booking.topic} at ${booking.scheduledTime}.`,
      type: 'booking_request',
      relatedId: booking._id
    });

    res.status(201).json(booking);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.getBookingsForStudent = async (req, res) => {
  try {
    const bookings = await Booking.find({ studentId: req.params.studentId }).populate('teacherId', 'name profileImageUrl').sort({ createdAt: -1 });
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getBookingsForTeacher = async (req, res) => {
  try {
    const bookings = await Booking.find({ teacherId: req.params.teacherId }).populate('studentId', 'name profileImageUrl interests level').sort({ createdAt: -1 });
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateBookingStatus = async (req, res) => {
  try {
    const { status, suggestedTime, topic, scheduledTime, notes } = req.body;
    
    // Fetch current booking
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });

    // VALIDATION: If accepting, check for double booking
    if (status === 'Accepted') {
      const overlapping = await Booking.findOne({
        teacherId: booking.teacherId,
        scheduledTime: scheduledTime || booking.scheduledTime,
        status: 'Accepted',
        _id: { $ne: booking._id }
      });
      if (overlapping) {
        return res.status(400).json({ message: 'You already have an accepted session at this time.' });
      }
    }

    const update = {};
    if (status) update.status = status;
    if (suggestedTime) update.suggestedTime = suggestedTime;
    if (topic) update.topic = topic;
    if (scheduledTime) update.scheduledTime = scheduledTime;
    if (notes) update.notes = notes;

    // AUTO-GENERATE MEETING LINK ON ACCEPT
    if (status === 'Accepted' && (!booking.meetingLink || scheduledTime)) {
      const roomId = `EmuLearn_${booking._id.toString().substring(0, 8)}_${Date.now().toString().substring(7)}`;
      update.meetingLink = `https://meet.jit.si/${roomId}`;
      update.meetingPassword = crypto.randomBytes(4).toString('hex'); // 8 char random hex
    }
    
    const updatedBooking = await Booking.findByIdAndUpdate(
      req.params.id,
      update,
      { new: true }
    ).populate('studentId', 'name profileImageUrl').populate('teacherId', 'name');

    // NOTIFY STUDENT OF STATUS CHANGE
    let notifTitle = 'Booking Update';
    let notifMsg = `Your booking for ${updatedBooking.topic} has been ${status.toLowerCase()}.`;
    let notifType = 'booking_status';

    if (status === 'Rescheduled') {
      notifTitle = 'Session Rescheduled';
      notifMsg = `${updatedBooking.teacherId?.name || 'The teacher'} has suggested a new time: ${suggestedTime}.`;
      notifType = 'reschedule';
    }

    await createInternalNotification({
      recipient: updatedBooking.studentId._id,
      sender: updatedBooking.teacherId._id,
      title: notifTitle,
      message: notifMsg,
      type: notifType,
      relatedId: updatedBooking._id
    });

    res.json(updatedBooking);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};
