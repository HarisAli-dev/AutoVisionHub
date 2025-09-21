const jwt = require('jsonwebtoken');
const User = require('../models/users/userModel');

// JWT Secret key - best practice is to use environment variables
const JWT_SECRET = process.env.JWT_SECRET;

// Middleware to protect routes - verify JWT token
exports.protect = async (req, res, next) => {
  let token;

  // Check for token in Authorization header
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // Get token from header
      token = req.headers.authorization.split(' ')[1];
      // Verify token
      const decoded = jwt.verify(token, JWT_SECRET);

      // Get user from token and attach to request object
      req.user = await User.findById(decoded.id).select('-password');

      if (!req.user) {
        return res.status(401).json({ message: 'Not authorized, user not found' });
      }

      next();
    } catch (error) {
      // Handle all token-related errors (invalid, expired, etc.)
      return res.status(401).json({ message: 'Not authorized, token failed' });
    }
  } else {
    return res.status(401).json({ message: 'Not authorized, no token' });
  }
};

// Admin middleware
exports.admin = (req, res, next) => {
  if (req.user && (req.user.isAdmin || req.user.role === 'admin')) {
    next();
  } else {
    res.status(403).json({ message: 'Not authorized as an admin' });
  }
};

