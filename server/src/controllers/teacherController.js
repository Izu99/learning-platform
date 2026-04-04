const TeacherProfile = require('../models/TeacherProfile');
const User = require('../models/User');
const Booking = require('../models/Booking');

exports.getAllTeachers = async (req, res) => {
  try {
    const profiles = await TeacherProfile.find({ status: 'active' }).populate('userId', 'name email profileImageUrl');
    const teachers = profiles.map(p => ({
      id: p.userId ? p.userId._id : p._id,
      profileId: p._id,
      name: p.userId ? p.userId.name : 'Unknown',
      email: p.userId ? p.userId.email : '',
      title: p.title,
      bio: p.bio,
      qualifications: p.qualifications,
      experienceYears: p.experienceYears,
      tags: p.tags,
      price: p.price,
      rating: p.rating,
      profileImageUrl: p.profileImageUrl || (p.userId ? p.userId.profileImageUrl : null),
      studentsCount: p.studentsCount,
      lessonsCount: p.lessonsCount,
      isVerified: p.isVerified,
      availability: p.availability
    }));
    res.json(teachers);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getTeacherProfile = async (req, res) => {
  try {
    const profile = await TeacherProfile.findOne({ userId: req.params.userId }).populate('userId', 'name email profileImageUrl');
    if (!profile) return res.status(404).json({ message: 'Profile not found' });
    res.json(profile);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.createOrUpdateProfile = async (req, res) => {
  try {
    const { name, title, bio, qualifications, experienceYears, tags, price, availability, profileImageUrl } = req.body;

    // Strip past dates: only keep today and future availability
    let cleanedAvailability = availability;
    if (availability && Array.isArray(availability)) {
      const todayStr = new Date().toISOString().split('T')[0]; // YYYY-MM-DD in UTC
      cleanedAvailability = availability.filter(d => d.date && d.date >= todayStr);

      // Validate overlaps only within each day (never cross-day)
      for (const dayAvail of cleanedAvailability) {
        if (!dayAvail.slots || !Array.isArray(dayAvail.slots) || dayAvail.slots.length < 2) {
          continue;
        }

        const sortedSlots = [...dayAvail.slots].sort((a, b) =>
          parseTimeToMinutes(a.start) - parseTimeToMinutes(b.start)
        );

        for (let i = 0; i < sortedSlots.length - 1; i++) {
          const currentEnd = parseTimeToMinutes(sortedSlots[i].end);
          const nextStart = parseTimeToMinutes(sortedSlots[i + 1].start);

          // nextStart must be strictly AFTER currentEnd (no overlap or touching)
          if (nextStart < currentEnd) {
            return res.status(400).json({
              message: `Availability overlap detected on ${dayAvail.date}: ${sortedSlots[i].start}-${sortedSlots[i].end} and ${sortedSlots[i+1].start}-${sortedSlots[i+1].end}. Please remove one.`
            });
          }
        }
      }
    }

    if (name || profileImageUrl) {
      await User.findByIdAndUpdate(req.user.id, {
        ...(name && { name }),
        ...(profileImageUrl && { profileImageUrl })
      });
    }

    // Build update object with only defined fields
    const updateData = {};
    if (title !== undefined) updateData.title = title;
    if (bio !== undefined) updateData.bio = bio;
    if (qualifications !== undefined) updateData.qualifications = qualifications;
    if (experienceYears !== undefined) updateData.experienceYears = experienceYears;
    if (tags !== undefined) updateData.tags = tags;
    if (price !== undefined) updateData.price = price;
    // Always use the cleaned availability (past dates stripped)
    if (availability !== undefined) updateData.availability = cleanedAvailability;
    if (profileImageUrl !== undefined) updateData.profileImageUrl = profileImageUrl;

    const profile = await TeacherProfile.findOneAndUpdate(
      { userId: req.user.id },
      { $set: updateData },
      { new: true, upsert: true }
    );
    res.status(200).json(profile);
  } catch (error) {
    console.error('Error updating teacher profile:', error);
    res.status(400).json({ message: error.message });
  }
};

// Upload profile image -> saves to uploads/teachers/ or uploads/students/
exports.uploadProfileImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No image file provided' });
    }

    const role = req.user?.role || 'student';
    const subfolder = role === 'teacher' ? 'teachers' : 'students';
    const imageUrl = `/uploads/${subfolder}/${req.file.filename}`;

    await User.findByIdAndUpdate(req.user.id, { profileImageUrl: imageUrl });

    if (role === 'teacher') {
      await TeacherProfile.findOneAndUpdate(
        { userId: req.user.id },
        { profileImageUrl: imageUrl },
        { upsert: false }
      );
    }

    res.status(200).json({ imageUrl, message: 'Profile image updated successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Allow teachers (and admins) to view basic student info for booking context
exports.getStudentForTeacher = async (req, res) => {
  try {
    // Only show phoneNumber to Admins
    const projection = req.user.role === 'admin' 
      ? 'name email profileImageUrl interests level createdAt phoneNumber role'
      : 'name email profileImageUrl interests level createdAt role';

    const student = await User.findById(req.params.studentId)
      .select(projection)
      .lean();
    
    if (!student || student.role === 'admin') {
      return res.status(404).json({ message: 'Student not found' });
    }

    res.status(200).json(student);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
// Get available 40-minute slots for a teacher on a specific date
exports.getAvailableSlots = async (req, res) => {
  try {
    const { teacherId } = req.params;
    const { date } = req.query; // Expecting YYYY-MM-DD
    
    if (process.env.NODE_ENV === 'test') {
      console.log('DEBUG: getAvailableSlots for teacherId:', teacherId, 'date:', date);
    }

    if (!date) return res.status(400).json({ message: 'Date is required' });

    const profile = await TeacherProfile.findOne({ userId: teacherId });
    
    if (process.env.NODE_ENV === 'test') {
      console.log('DEBUG: Found profile:', profile ? 'YES' : 'NO');
    }

    if (!profile) return res.status(404).json({ message: 'Teacher profile not found' });

    // Find availability block for this date
    const dayAvail = profile.availability.find(a => a.date === date);
    if (!dayAvail || !dayAvail.slots.length) {
      return res.json([]); // No availability for this day
    }

    // Fetch existing bookings for this teacher and date
    // We check for any booking that starts on this date
    const existingBookings = await Booking.find({
      teacherId,
      status: { $in: ['Pending', 'Accepted'] },
      scheduledTime: { $regex: `^${date}` } 
    }).select('scheduledTime');

    const bookedTimes = existingBookings.map(b => b.scheduledTime);

    const SLOTT_DURATION = 40; // minutes
    const BUFFER = 5; // minutes
    const INTERVAL = SLOTT_DURATION + BUFFER;

    let availableSlots = [];

    dayAvail.slots.forEach(block => {
      let currentMinutes = parseTimeToMinutes(block.start);
      const endMinutes = parseTimeToMinutes(block.end);

      // Generate 40-minute slots with a 5-minute breather
      while (currentMinutes + SLOTT_DURATION <= endMinutes) {
        const h = Math.floor(currentMinutes / 60);
        const m = currentMinutes % 60;
        const timeStr = `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
        const fullDateTime = `${date}T${timeStr}:00.000Z`;

        if (!bookedTimes.includes(fullDateTime)) {
          availableSlots.push({
            time: timeStr,
            fullDateTime: fullDateTime,
            available: true
          });
        }

        currentMinutes += INTERVAL;
      }
    });

    res.json(availableSlots);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Helper function to convert "HH:MM" to minutes past midnight
const parseTimeToMinutes = (time) => {
  const [hours, minutes] = time.split(':').map(Number);
  return hours * 60 + minutes;
};
