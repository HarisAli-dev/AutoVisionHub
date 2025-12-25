// middleware/bannedUserMiddleware.js
const User = require('../models/users/userModel');

// Middleware to check if user is banned
exports.checkBanned = async (req, res, next) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    // Find user by email
    const user = await User.findOne({ email });
    
    if (!user) {
      // If user doesn't exist, let the controller handle it
      return next();
    }

    // Check if user is banned
    if (user.isBanned) {
      return res.status(403).json({ 
        message: 'Your account has been banned. Please contact support or request an unban.',
        isBanned: true
      });
    }

    // User is not banned, proceed
    next();
  } catch (err) {
    res.status(500).json({ message: 'Error checking ban status', error: err.message });
  }
};
