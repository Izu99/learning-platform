const User = require('../models/User');
const TeacherProfile = require('../models/TeacherProfile');
const jwt = require('jsonwebtoken');
const { createInternalNotification } = require('./notificationController');

const JWT_SECRET = process.env.JWT_SECRET || 'supersecretjwtkey';

exports.register = async (req, res) => {
  try {
    const { name, email, password, role, phoneNumber, ...profileData } = req.body;
    const lowerRole = role ? role.toLowerCase() : 'student';
    
    // 1. Create the User
    const user = new User({ name, email, password, role: lowerRole, phoneNumber });
    await user.save();
    
    // 2. If Teacher, create the Profile
    let teacherProfile = null;
    if (lowerRole === 'teacher') {
      teacherProfile = new TeacherProfile({
        userId: user._id,
        title: profileData.title || 'Professional Teacher',
        bio: profileData.bio || 'No bio provided yet.',
        experienceYears: profileData.experienceYears || 0,
        price: profileData.price || 0,
        tags: profileData.tags || [],
        qualifications: profileData.qualifications || [],
        profileImageUrl: profileData.profileImageUrl || ''
      });
      await teacherProfile.save();

      // NOTIFY ADMINS
      const admins = await User.find({ role: 'admin' });
      for (const admin of admins) {
        await createInternalNotification({
          recipient: admin._id,
          sender: user._id,
          title: 'New Teacher Registration',
          message: `${user.name} has registered as a teacher and is awaiting approval.`,
          type: 'teacher_registration',
          relatedId: teacherProfile._id
        });
      }
    }
    
    const userData = { id: user._id, role: user.role };
    const token = jwt.sign({ user: userData }, JWT_SECRET, { expiresIn: '1d' });
    
    res.status(201).json({ 
      token, 
      user: { id: user._id, name: user.name, email: user.email, role: user.role, phoneNumber: user.phoneNumber },
      profile: teacherProfile
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    // Consistent payload structure: { user: { id, role } }
    const userData = { id: user._id, role: user.role };
    const token = jwt.sign({ user: userData }, JWT_SECRET, { expiresIn: '1d' });
    
    res.json({ 
      token, 
      user: { 
        id: user._id, 
        name: user.name, 
        email: user.email, 
        role: user.role,
        interests: user.interests,
        level: user.level,
        phoneNumber: user.phoneNumber
      } 
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.updatePreferences = async (req, res) => {
  try {
    const { interests, level } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user.id, 
      { interests, level }, 
      { new: true }
    );
    res.json(user);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};
