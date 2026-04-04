const User = require('../models/User');
const TeacherProfile = require('../models/TeacherProfile');
const { createInternalNotification } = require('./notificationController');

// List all teachers (admin view) - Showing pending profiles
exports.listTeachers = async (req, res) => {
  try {
    const profiles = await TeacherProfile.find({}).populate('userId', 'name email phoneNumber');
    
    // Map to a friendlier format for Flutter
    const teachers = profiles.map(p => ({
      _id: p._id,
      name: p.userId ? p.userId.name : 'Unknown',
      email: p.userId ? p.userId.email : 'No Email',
      phoneNumber: p.userId ? p.userId.phoneNumber : 'No Phone',
      title: p.title,
      status: p.status,
      isVerified: p.isVerified,
      userId: p.userId // Keep it for Teacher.fromJson mapping
    }));
    
    res.status(200).json(teachers);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// View a single teacher by ID
exports.viewTeacher = async (req, res) => {
  try {
    const profile = await TeacherProfile.findById(req.params.id).populate('userId', 'name email phoneNumber');
    if (!profile) {
      return res.status(404).json({ message: 'Teacher profile not found' });
    }
    res.status(200).json(profile);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update teacher status (Approve/Reject)
exports.updateTeacherStatus = async (req, res) => {
  try {
    let { status } = req.body;
    if (!status) {
      return res.status(400).json({ message: 'Status is required' });
    }

    // Map 'approved' from frontend to 'active' in DB
    let mappedStatus = status.toLowerCase();
    if (mappedStatus === 'approved') {
      mappedStatus = 'active';
    }

    const profile = await TeacherProfile.findByIdAndUpdate(
      req.params.id,
      { 
        status: mappedStatus,
        isVerified: mappedStatus === 'active' 
      },
      { new: true, runValidators: true }
    );

    if (!profile) {
      return res.status(404).json({ message: 'Teacher profile not found' });
    }

    // NOTIFY TEACHER
    await createInternalNotification({
      recipient: profile.userId,
      sender: req.user._id,
      title: 'Account Status Updated',
      message: `Your teacher account has been ${mappedStatus === 'active' ? 'approved' : 'moved to ' + mappedStatus}.`,
      type: 'teacher_approval',
      relatedId: profile._id
    });

    res.status(200).json(profile);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get dashboard metrics
exports.getDashboardMetrics = async (req, res) => {
  try {
    const totalTeachers = await User.countDocuments({ role: 'teacher' });
    const totalStudents = await User.countDocuments({ role: 'student' });
    const pendingTeachers = await TeacherProfile.countDocuments({ status: 'pending' });

    res.status(200).json({
      totalTeachers,
      totalStudents,
      pendingTeachers,
      activeSessions: 0 
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// List all users in the system (Admins, Teachers, Students)
exports.listUsers = async (req, res) => {
  try {
    const { role } = req.query;
    const filter = role ? { role: role.toLowerCase() } : {};
    
    const users = await User.find(filter).sort({ createdAt: -1 }).lean();
    
    // Enrich users with teacher profile data if role is teacher
    const enrichedUsers = await Promise.all(users.map(async (u) => {
      if (u.role === 'teacher') {
        const profile = await TeacherProfile.findOne({ userId: u._id }).lean();
        return {
          ...u,
          status: profile ? profile.status : 'pending',
          profileId: profile ? profile._id : null,
          isVerified: profile ? profile.isVerified : false,
          // Full profile for admin detail popup
          title: profile ? profile.title : '',
          bio: profile ? profile.bio : '',
          price: profile ? profile.price : 0,
          rating: profile ? profile.rating : 0,
          studentsCount: profile ? profile.studentsCount : 0,
          lessonsCount: profile ? profile.lessonsCount : 0,
          experienceYears: profile ? profile.experienceYears : 0,
          tags: profile ? (profile.tags || []) : [],
          qualifications: profile ? (profile.qualifications || []) : [],
          availability: profile ? (profile.availability || []) : [],
          profileImageUrl: profile?.profileImageUrl || u.profileImageUrl || null,
        };
      }
      return { ...u, status: 'active' };
    }));

    res.status(200).json(enrichedUsers);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


// Get student details
exports.getStudentDetails = async (req, res) => {
  try {
    const student = await User.findById(req.params.id); 
    if (!student || student.role !== 'student') {
      return res.status(404).json({ message: 'Student not found or not a student' });
    }
    res.status(200).json(student);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};