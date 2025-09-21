// controllers/chatController.js
const Chat = require('../../models/chats/chatModel');
const User = require('../../models/users/userModel');
const Message = require('../../models/chats/chatMessageModel');
const { getIO } = require('../../config/socket');

/**
 * Create a new chat between users
 * @route POST /api/chat
 * @access Private
 */
exports.createNewChat = async (req, res) => {
  try {
    const { userId } = req.body; // User to chat with
    const currentUserId = req.user.id; // Current authenticated user
    
    // Check if users exist
    const otherUser = await User.findById(userId);
    if (!otherUser) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Create a new chat
    const newChat = new Chat({
      participants: [currentUserId, userId],
      createdBy: currentUserId,
      unreadCounts: {
        [currentUserId]: 0,
        [userId]: 0
      }
    });
    
    await newChat.save();
    
    // Populate the chat with user details
    const populatedChat = await Chat.findById(newChat._id)
      .populate('participants', 'name email');
    
    // Notify the other user about the new chat
    const io = getIO();
    io.to(userId).emit('newChat', populatedChat);
    
    res.status(201).json(populatedChat);
  } catch (error) {
    console.error('Error creating chat:', error);
    res.status(500).json({ message: 'Failed to create chat', error: error.message });
  }
};

/**
 * Get or create a chat between two users
 * @route GET /api/chat/user/:userId
 * @access Private
 */
exports.getChatBetweenUsers = async (req, res) => {
  try {
    const { chatId } = req.params;
    // Find the chat by ID
    const chat = await Chat.findById(chatId)
      .populate('participants', 'name email')
      .populate('lastMessage');

    if (!chat) {
      return res.status(404).json({ message: 'Chat not found' });
    }
    // get  all messages for this chat
    const messages = await Message.find({ chatId })
      .populate('senderName', 'name email')
      .sort({ createdAt: -1 });
    res.json({ chat, messages });
  } catch (error) {
    console.error('Error getting/creating chat:', error);
    res.status(500).json({ message: 'Failed to get or create chat', error: error.message });
  }
};

/**
 * Delete chat between users (soft delete by marking as deleted for current user)
 * @route DELETE /api/chat/:chatId
 * @access Private
 */
exports.deleteChatBetweenUsers = async (req, res) => {
  try {
    const { chatId } = req.body;
    const userId = req.user.id;
    
    const chat = await Chat.findById(chatId);
    
    if (!chat) {
      return res.status(404).json({ message: 'Chat not found' });
    }
    
    // Make sure user is a participant
    if (!chat.participants.includes(userId)) {
      return res.status(403).json({ message: 'Not authorized to delete this chat' });
    }
    
    // Option 1: Hard delete the chat if both users delete it
    // This approach is for a simple implementation
    // We're deleting the entire chat
    await Chat.findByIdAndDelete(chatId);
    
    // Delete all associated messages
    await Message.deleteMany({ chatId });
    
    // Notify the other participants
    const io = getIO();
    chat.participants.forEach(participantId => {
      if (participantId.toString() !== userId) {
        io.to(participantId.toString()).emit('chatDeleted', { chatId });
      }
    });
    
    res.status(200).json({ message: 'Chat deleted successfully' });

    /* Option 2: For a more sophisticated approach with soft delete (implement later)
    // Add deletedBy field to the chat model first
    // chat.deletedBy = chat.deletedBy || [];
    // if (!chat.deletedBy.includes(userId)) {
    //   chat.deletedBy.push(userId);
    // }
    // await chat.save();
    */
  } catch (error) {
    console.error('Error deleting chat:', error);
    res.status(500).json({ message: 'Failed to delete chat', error: error.message });
  }
};

/**
 * Get all chats for the current user
 * @route GET /api/chat
 * @access Private
 */
exports.getChatsForUser = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Find all chats that include this user
    const chats = await Chat.find({
      participants: userId
    })
      .populate('participants', 'name email')
      .populate('lastMessage')
      .sort({ updatedAt: -1 });  // Most recent chats first
    
    res.json(chats);
  } catch (error) {
    console.error('Error getting chats:', error);
    res.status(500).json({ message: 'Failed to retrieve chats', error: error.message });
  }
};

/**
 * Get all messages for a specific chat
 * @route GET /api/chat/:chatId/messages
 * @access Private
 */
exports.getChatMessages = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user.id;
    
    // Verify chat exists and user is a participant
    const chat = await Chat.findById(chatId);
    if (!chat) {
      return res.status(404).json({ message: 'Chat not found' });
    }
    
    if (!chat.participants.includes(userId)) {
      return res.status(403).json({ message: 'Not authorized to access this chat' });
    }
    
    // Get messages for the chat, excluding ones deleted for this user
    const messages = await Message.find({
      chatId,
      $or: [
        { isDeleted: false },
        { isDeleted: true, deletedFor: { $nin: [userId] } }
      ]
    }).sort({ createdAt: -1 }).limit(50);  // Most recent 50 messages
    
    // Mark messages as read
    await Message.updateMany(
      { chatId, senderId: { $ne: userId }, status: { $ne: 'seen' } },
      { status: 'seen' }
    );
    
    // Reset unread count for this user
    if (chat.unreadCounts && chat.unreadCounts.get(userId) > 0) {
      chat.unreadCounts.set(userId, 0);
      await chat.save();
    }
    
    // Notify other users that messages were seen
    const io = getIO();
    chat.participants.forEach(participantId => {
      if (participantId.toString() !== userId) {
        io.to(participantId.toString()).emit('messagesRead', {
          chatId,
          readBy: userId
        });
      }
    });
    
    res.json(messages);  // Return in chronological order (oldest first)
  } catch (error) {
    console.error('Error getting chat messages:', error);
    res.status(500).json({ message: 'Failed to retrieve messages', error: error.message });
  }
};

// Group chat functionality removed

/**
 * Update a chat's unread count for a user
 * @route PATCH /api/chat/:chatId/read
 * @access Private
 */
exports.markChatAsRead = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user.id;
    
    const chat = await Chat.findById(chatId);
    if (!chat) {
      return res.status(404).json({ message: 'Chat not found' });
    }
    
    if (!chat.participants.includes(userId)) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    // Update unread count for the user
    if (chat.unreadCounts) {
      chat.unreadCounts.set(userId, 0);
      await chat.save();
    }
    
    // Mark all messages as seen
    await Message.updateMany(
      { chatId, senderId: { $ne: userId }, status: { $ne: 'seen' } },
      { status: 'seen' }
    );
    
    // Notify other participants
    const io = getIO();
    chat.participants.forEach(participantId => {
      if (participantId.toString() !== userId) {
        io.to(participantId.toString()).emit('chatRead', {
          chatId,
          readBy: userId
        });
      }
    });
    
    res.json({ message: 'Chat marked as read' });
  } catch (error) {
    console.error('Error marking chat as read:', error);
    res.status(500).json({ message: 'Failed to mark chat as read', error: error.message });
  }
};

// Group chat functionality removed

