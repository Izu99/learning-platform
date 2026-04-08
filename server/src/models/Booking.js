const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  topic: { type: String, required: true },
  scheduledTime: { type: String, required: true },
  suggestedTime: { type: String }, // For rescheduling flow
  status: { 
    type: String, 
    enum: ['Pending', 'Accepted', 'Rejected', 'Completed', 'Cancelled', 'Rescheduled'], 
    default: 'Pending' 
  },
  notes: String,
  meetingLink: { type: String }, // Auto-generated Jitsi Link
  meetingPassword: { type: String }, // For secure access
  rescheduledBy: { type: String, enum: ['teacher', 'student'] }, // Who initiated the reschedule
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Booking', bookingSchema);
