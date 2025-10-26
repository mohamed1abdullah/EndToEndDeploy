const jwt = require('jsonwebtoken');

module.exports = function (req, res, next) {
  // 1. Get the full Authorization header from the request
  const authHeader = req.header('Authorization');
  console.log('[LOG] Checking for Authorization header...');

  // 2. Check if the header exists
  if (!authHeader) {
    console.warn('[WARN] Auth failed: No Authorization header found.');
    return res.status(401).json({ msg: 'No token provided, authorization denied' });
  }

  // 3. Check if the header is in the "Bearer <token>" format and split it
  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    console.warn('[WARN] Auth failed: Token is not in "Bearer <token>" format.');
    return res.status(401).json({ msg: 'Token is malformed' });
  }
  
  const token = parts[1];
  console.log('[LOG] Token found, attempting to verify...');

  // 4. Verify the extracted token
  try {
    const decoded = jwt.verify(token, 'your-jwt-secret'); // Use the same secret key
    req.user = decoded.user;
    console.log(`[LOG] Token verified for user ID: ${req.user.id}`);
    next();
  } catch (err) {
    console.error('[ERROR] Auth failed: Token is not valid.', err.message);
    res.status(401).json({ msg: 'Token is not valid' });
  }
};
