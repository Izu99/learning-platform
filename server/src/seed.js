require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const TeacherProfile = require('./models/TeacherProfile');
const Booking = require('./models/Booking');

const MONGO_URI = process.env.MONGO_URI;

const seedData = async () => {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('Connected to MongoDB for seeding...');

    // Clear all
    await User.deleteMany({});
    await TeacherProfile.deleteMany({});
    await Booking.deleteMany({});

    // 1. Create Users
    const student1 = new User({
      name: 'Isuru Student',
      email: 'student@emu.com',
      password: 'password123',
      role: 'Student',
      interests: ['IELTS', 'Speaking'],
      level: 'Intermediate'
    });
    await student1.save();

    const teacherUser1 = new User({
      name: 'Sarah Jenkins',
      email: 'sarah@emu.com',
      password: 'password123',
      role: 'Teacher'
    });
    await teacherUser1.save();

    const teacherUser2 = new User({
      name: 'Marcus Thompson',
      email: 'marcus@emu.com',
      password: 'password123',
      role: 'Teacher'
    });
    await teacherUser2.save();

    const teacherUser3 = new User({
      name: 'Elena Rodriguez',
      email: 'elena@emu.com',
      password: 'password123',
      role: 'Teacher'
    });
    await teacherUser3.save();

    // 2. Create Teacher Profiles
    const profile1 = new TeacherProfile({
      userId: teacherUser1._id,
      title: 'IELTS Specialist & ESL Coach',
      bio: 'Dedicated IELTS specialist with a passion for helping students achieve their target bands. My methodology focuses on exam techniques and expanding vocabulary range.',
      qualifications: [{ title: 'CELTA Certified', institution: 'Cambridge English' }],
      experienceYears: 8,
      tags: ['IELTS Speaking', 'Academic Writing', 'Grammar Fundamentals'],
      price: 35,
      rating: 4.9,
      reviewCount: 124,
      studentsCount: 450,
      lessonsCount: 1200,
      isVerified: true,
      availability: [
        { day: 'Mon', slots: [{ start: '09:00 AM', end: '10:00 AM' }, { start: '11:00 AM', end: '12:00 PM' }] },
        { day: 'Wed', slots: [{ start: '04:30 PM', end: '05:30 PM' }] }
      ]
    });
    await profile1.save();

    const profile2 = new TeacherProfile({
      userId: teacherUser2._id,
      title: 'Native Spanish Speaker & English Tutor',
      bio: 'Experienced in bilingual education and specialized in grammar coaching for advanced learners.',
      qualifications: [{ title: 'MA in Applied Linguistics', institution: 'University of Madrid' }],
      experienceYears: 10,
      tags: ['Grammar Basics', 'Business English', 'Pronunciation'],
      price: 32,
      rating: 4.8,
      reviewCount: 92,
      studentsCount: 380,
      lessonsCount: 950,
      isVerified: true,
      availability: [
        { day: 'Tue', slots: [{ start: '10:00 AM', end: '11:00 AM' }] },
        { day: 'Thu', slots: [{ start: '02:00 PM', end: '03:00 PM' }] }
      ]
    });
    await profile2.save();

    // 3. Create Sample Bookings
    const booking1 = new Booking({
      studentId: student1._id,
      teacherId: teacherUser1._id,
      topic: 'Speaking Practice',
      scheduledTime: 'Today, 4:30 PM',
      status: 'Accepted',
      notes: 'I want to focus on Part 2 of the IELTS speaking test.'
    });
    await booking1.save();

    const booking2 = new Booking({
      studentId: student1._id,
      teacherId: teacherUser2._id,
      topic: 'Grammar Basics',
      scheduledTime: 'Tomorrow, 10:00 AM',
      status: 'Pending',
      notes: 'Need help with conditional sentences.'
    });
    await booking2.save();

    console.log('Database seeded with English Learning content successfully!');
    process.exit();
  } catch (error) {
    console.error('Seeding error:', error);
    process.exit(1);
  }
};

seedData();
