const mongoose = require('mongoose');

const teacherSchema = new mongoose.Schema({
  name: { type: String, required: true },
  title: { type: String, required: true },
  location: { type: String, required: true },
  rating: { type: Number, default: 0 },
  about: { type: String },
  isOnline: { type: Boolean, default: false },
  studentsCount: { type: Number, default: 0 },
  lessonsCount: { type: Number, default: 0 },
  hoursCount: { type: Number, default: 0 },
  status: { type: String, default: 'pending' },
  tags: [String],
  sessionTopics: [String],
  timeSlots: [{
    start: String,
    end: String
  }],
});

module.exports = mongoose.model('Teacher', teacherSchema);
