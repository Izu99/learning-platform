const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const sanitize = require('mongo-sanitize');
const hpp = require('hpp');
const { morganMiddleware, detailedLogger } = require('./middleware/logger');
const app = express();

// Security Middleware
app.use(helmet()); // Basic security headers

// Prevent NoSQL Injection (Safe implementation for Express 5)
if (process.env.NODE_ENV !== 'test') {
  app.use((req, res, next) => {
    req.body = sanitize(req.body);
    req.params = sanitize(req.params);
    // Note: req.query is read-only in Express 5, so we cannot sanitize it by overwriting the whole object.
    // Instead, individual properties would need to be sanitized if they are used as MongoDB filters.
    // But for most cases, body and params are the main injection vectors.
    next();
  });
}

app.use(hpp()); // Prevent Parameter Pollution

// Rate Limiting (General)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per window
  message: 'Too many requests from this IP, please try again after 15 minutes'
});
app.use('/api', limiter);

// Strict Rate Limiting for Auth
const authLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10, // Limit login attempts to 10 per hour
  message: 'Too many login attempts, please try again in an hour'
});
app.use('/api/auth/login', authLimiter);

// CORS configuration - Limit to specific origins in PRODUCTION
app.use(cors({
  origin: '*', // For local dev, allow all. Change to your domain in production
  methods: 'GET,POST,PUT,PATCH,DELETE',
  allowedHeaders: 'Content-Type,Authorization,x-auth-token'
}));

app.use(express.json({ limit: '10kb' })); // Body parser with size limit for security

// Serve uploaded images (profile photos, etc.)
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// Logging Middleware (Detailed + Morgan)
app.use(detailedLogger);
app.use(morganMiddleware);

// Import Routes
const authRoutes = require('./routes/authRoutes');
const teacherRoutes = require('./routes/teacherRoutes');
const sessionRoutes = require('./routes/sessionRoutes'); // Keep for backward compatibility if needed, or deprecate
const bookingRoutes = require('./routes/bookingRoutes');
const adminRoutes = require('./routes/adminRoutes');
const notificationRoutes = require('./routes/notificationRoutes');

// Use Routes
app.use('/api/auth', authRoutes);
app.use('/api/teachers', teacherRoutes);
app.use('/api/sessions', sessionRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/notifications', notificationRoutes);

// Basic Route
app.get('/', (req, res) => {
  res.send('EduLearn API is running...');
});

module.exports = app;
