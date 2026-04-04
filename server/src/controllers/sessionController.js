const Session = require('../models/Session');

exports.createSessionRequest = async (req, res) => {
  try {
    const session = new Session(req.body);
    await session.save();
    res.status(201).json(session);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.getSessionsForTeacher = async (req, res) => {
  try {
    const sessions = await Session.find({ teacherId: req.params.teacherId });
    res.json(sessions);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateSessionStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const session = await Session.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true }
    );
    if (!session) return res.status(404).json({ message: 'Session not found' });
    res.json(session);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};
