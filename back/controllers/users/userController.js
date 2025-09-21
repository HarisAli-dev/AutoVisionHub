// controllers/userController.js
const User = require('../../models/users/userModel');
const Chat = require('../../models/chats/chatModel');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

/**
 * Get a list of users with whom the current user has not chatted yet
 * @route GET /api/users/new-chat-users/:userId
 * @access Public
 */
exports.chatWithNewUserList = async (req, res) => {
  try {
    const { userId } = req.params; // Get userId from URL parameters
    
    // Find all chats where this user is a participant - using aggregation for better performance
    const chatParticipants = await Chat.aggregate([
      // Match chats where the user is a participant
      { $match: { participants: new mongoose.Types.ObjectId(userId) } },
      // Unwind participants array to have one document per participant
      { $unwind: "$participants" },
      // Filter out the current user
      { $match: { participants: { $ne: new mongoose.Types.ObjectId(userId) } } },
      // Group by participant ID to get unique users
      { $group: { _id: "$participants" } }
    ]);
    
    // Extract participant IDs
    const existingChatUserIds = chatParticipants.map(item => item._id);
    
    // Build the query
    const query = {
      _id: { 
        $ne: userId,                 // Not the current user
        $nin: existingChatUserIds,   // Not already in a chat with the user
      },
      role: { $ne: 'admin' }  
    };
    
    // Find all users matching the query without pagination
    const usersToChat = await User.find(query)
      .select('_id name email role')
      .sort({ name: 1 }); // Sort alphabetically by name
    
    // Return just the users array
    res.json({
      users: usersToChat
    });
  } catch (error) {
    console.error('Error getting users to chat with:', error);
    res.status(500).json({ message: 'Failed to get users', error: error.message });
  }
};

/**
 * Search for users by name or email
 * @route GET /api/users/search/:query
 * @access Private
 */
exports.searchUser = async (req, res) => {
  try {
    const { query } = req.params;
    const { page = 1, limit = 20, excludeCurrentUser = 'false' } = req.query;
    
    // Convert page and limit to numbers
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    
    // Build query
    const searchQuery = {
      $or: [
        { name: { $regex: query, $options: 'i' } },
        { email: { $regex: query, $options: 'i' } },
      ]
    };
    
    // Exclude current user if requested
    if (excludeCurrentUser === 'true') {
      searchQuery._id = { $ne: req.user.id };
    }
    
    // Count total matching users for pagination
    const total = await User.countDocuments(searchQuery);
    
    if (total === 0) {
      return res.status(200).json({
        users: [],
        pagination: {
          total: 0,
          page: pageNum,
          limit: limitNum,
          pages: 0
        },
        message: 'No users found'
      });
    }
    
    // Find users with pagination
    const users = await User.find(searchQuery)
      .select('_id name email role') // Include more useful fields, but still protect sensitive data
      .sort({ name: 1 }) // Sort alphabetically
      .skip((pageNum - 1) * limitNum)
      .limit(limitNum);
    
    // Return with pagination metadata
    res.status(200).json({
      users,
      pagination: {
        total,
        page: pageNum,
        limit: limitNum,
        pages: Math.ceil(total / limitNum)
      }
    });
  } catch (error) {
    console.error('Error searching for users:', error);
    res.status(500).json({ message: 'Error searching for users', error: error.message });
  }
};

//get all users - for admin use
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find(
      { _id: { $ne: req.user.id }, role: { $ne: 'admin' } }
    )
      .select('-password') // Exclude password field
      .sort({ name: 1 }); // Sort alphabetically by name
    res.status(200).json(users);
  } catch (error) {
    console.error('Error fetching all users:', error);
    res.status(500).json({ message: 'Error fetching users', error: error.message });
  }
}

// Get user profile
exports.getProfile = async (req, res) => {
  const userId = req.user.id;
  try {
    const user = await User.findById(userId);
    // decrypt password before sending


    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.status(200).json(user);
  } catch (err) {
    res.status(500).json({ message: 'Error fetching profile', error: err.message });
  }
};

// Update user profile
exports.updateProfile = async (req, res) => {
  const { name, phoneNumber, city ,profileImageUrl} = req.body;
  const userId = req.user.id;
  try {
    // chechk if phone number is already in use by another user
    const existingUser = await User.findOne({ phoneNumber, _id: { $ne: userId } });
    if (existingUser) {
      return res.status(400).json({ message: 'Phone number already in use by another user' });
    }
    const updateData = {
      name,
      phoneNumber,
      city,
      profileImageUrl: profileImageUrl
    };

    const user = await User.findByIdAndUpdate(userId, updateData, {
      new: true,
      runValidators: true,
    });
    

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({ message: 'Profile updated successfully', user });
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ message: 'Failed to update profile', error: error.message });
  }
};

// Change user password
exports.changePassword = async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  const userId = req.user.id;
  try {
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    // Check if current password matches
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Current password is incorrect' });
    }

    // Update password
    user.password = await bcrypt.hash(newPassword, 10);
    await user.save();

    res.status(200).json({ message: 'Password changed successfully' });
  } catch (error) {
    console.error('Error changing password:', error);
    res.status(500).json({ message: 'Failed to change password', error: error.message });
  }
};
