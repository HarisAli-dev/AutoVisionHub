// controllers/authController.js
const User = require('../../models/users/userModel');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Group = require('../../models/groups/groupModel'); // Assuming Group model is defined

//check for token expiry
exports.checkTokenExpiry = (req, res, next) => {
  const token = req.params.token;
  const JWT_SECRET = process.env.JWT_SECRET;

  if (!token) {
    return res.status(401).json({ message: 'Not authorized, no token' });
  }

  jwt.verify(token, JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(401).json({ message: 'Not authorized, token expired' });
    }
    res.status(200).json({ message: true, decoded });
  });
};

// User registration
exports.register = async (req, res) => {
  const { name, email, password, phoneNumber, city, role } = req.body;

  try {
    // Check if the email already exists
    const emailExists = await User.findOne({ email });
    if (emailExists) {
      return res.status(400).json({ message: 'Email already in use' });
    }
    
    // Check if the phone number already exists
    const phoneExists = await User.findOne({ phoneNumber });
    if (phoneExists) {
      return res.status(400).json({ message: 'Phone number already in use' });
    }

    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await User.create({
      name,
      email,
      password: hashedPassword,
      phoneNumber,
      city,
      role: role || 'community_member',  // Use provided role or default
      profileImageUrl: null
    });

    res.status(201).json({
      message: 'User created successfully',
      user: { 
        id: newUser._id,
        name: newUser.name, 
        email: newUser.email, 
        role: newUser.role,
        phoneNumber: newUser.phoneNumber,
        city: newUser.city 
      },
    });
  } catch (err) {
    res.status(500).json({ message: 'Error creating user', error: err.message });
  }
};

// User login
exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    // Find the user by email
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(400).json({ message: 'Invalid User does not exist' });
    }
  
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(400).json({ message: 'Invalid password' });
    }

    // Generate JWT token
    const JWT_SECRET = process.env.JWT_SECRET || '116f18f26b7742993c7f536f99c2210e93dd65e1536fa7151db23940aa90b73734e2a3b3ea6d772038be6de87acb93c3e3feff607ff736a3bce062fccc4648a3';
    const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, { expiresIn: '10h' });

    // Send response with token, user role, and user details
    res.status(200).json({
      token,
      userId: user._id,
      userName: user.name,
      role: user.role,
      email: user.email,
      phoneNumber: user.phoneNumber,
      city: user.city
    });
  } catch (err) {
    res.status(500).json({ message: 'Error logging in', error: err.message });
  }
};

// Delete user profile
exports.deleteProfile = async (req, res) => {
  const userId = req.params.userId;
  
  try {
    // Find and delete the user
    const deletedUser = await User.findByIdAndDelete(userId);
    
    if (!deletedUser) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // TODO: You might want to also delete user's chats, messages, etc.
    // This would require additional logic to clean up related data
    
    res.status(200).json({
      message: 'Profile deleted successfully'
    });
  } catch (err) {
    res.status(500).json({ message: 'Error deleting profile', error: err.message });
  }
};

