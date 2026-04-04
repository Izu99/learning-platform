const morgan = require('morgan');

// Standard morgan format for basic request info
const morganMiddleware = morgan('dev');

// Custom detailed logger
const detailedLogger = (req, res, next) => {
  const start = Date.now();
  
  // Clean body for logging (mask passwords)
  let logBody = { ...req.body };
  if (logBody.password) logBody.password = '********';
  if (logBody.token) logBody.token = '********';

  // Log when request starts
  console.log(`\n[${new Date().toISOString()}] REQUEST: ${req.method} ${req.originalUrl}`);
  if (Object.keys(req.query).length > 0) {
    console.log('QUERY:', JSON.stringify(req.query, null, 2));
  }
  if (Object.keys(logBody).length > 0) {
    console.log('BODY:', JSON.stringify(logBody, null, 2));
  }

  // Hook into response finish to log completion
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`[${new Date().toISOString()}] RESPONSE: ${res.statusCode} (${duration}ms)`);
  });

  next();
};

module.exports = { morganMiddleware, detailedLogger };
