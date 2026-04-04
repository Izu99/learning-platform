const mongoose = require('mongoose');

const teacherProfileSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  title: { type: String, required: true },
  bio: { type: String, required: true },
  profileImageUrl: { type: String },
  qualifications: [{
    title: String,
    institution: String
  }],
  experienceYears: { type: Number, default: 0 },
  tags: [String], // English topics like IELTS, Speaking
  price: { type: Number, default: 0 },
  rating: { type: Number, default: 5.0 },
  reviewCount: { type: Number, default: 0 },
  studentsCount: { type: Number, default: 0 },
  lessonsCount: { type: Number, default: 0 },
  isVerified: { type: Boolean, default: false },
  status: { type: String, enum: ['pending', 'active', 'rejected'], default: 'pending' },
  availability: [{
    date: String, // Format: YYYY-MM-DD for specific date scheduling
    slots: [{
      start: String,
      end: String,
      available: { type: Boolean, default: true }
    }]
  }]
});

module.exports = mongoose.model('TeacherProfile', teacherProfileSchema);
