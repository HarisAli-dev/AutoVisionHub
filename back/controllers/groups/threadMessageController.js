const ThreadMessage = require('../../models/groups/threadMessageModel');
const Thread = require('../../models/groups/threadModel');
const User = require('../../models/users/userModel');

// Send a message to a thread
exports.sendThreadMessage = async (req, res) => {
  try {
    const { threadId, message } = req.body;
    const userId = req.user.id;

    if (!message || message.trim().length === 0) {
      return res.status(400).json({ error: 'Message cannot be empty' });
    }

    const thread = await Thread.findById(threadId);
    if (!thread) {
      return res.status(404).json({ error: 'Thread not found' });
    }

    if (!thread.isActive) {
      return res.status(400).json({ error: 'This thread is no longer active' });
    }

    if (!thread.participants.includes(userId)) {
      return res.status(403).json({ error: 'You must join the thread to send messages' });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const threadMessage = new ThreadMessage({
      threadId,
      senderId: userId,
      senderName: user.name,
      senderImageUrl: user.profileImageUrl,
      message: message.trim()
    });

    await threadMessage.save();

    // Update thread's last message and message count
    thread.lastMessage = threadMessage._id;
    thread.messageCount += 1;
    await thread.save();

    // Populate sender details
    await threadMessage.populate('senderId', 'name email profileImageUrl');

    // Make io available to controller
    res.status(200).json({ success: true, message: threadMessage });
  } catch (error) {
    console.error('Error sending thread message:', error);
    res.status(500).json({ error: 'Failed to send message' });
  }
};

// Get thread messages
exports.getThreadMessages = async (req, res) => {
  try {
    const { threadId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const skip = (page - 1) * limit;

    const thread = await Thread.findById(threadId);
    if (!thread) {
      return res.status(404).json({ error: 'Thread not found' });
    }

    const messages = await ThreadMessage.find({
      threadId,
      isDeleted: false
    })
      .populate('senderId', 'name email profileImageUrl')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const totalMessages = await ThreadMessage.countDocuments({
      threadId,
      isDeleted: false
    });

    res.status(200).json({
      messages: messages.reverse(), // Reverse to show oldest first
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalMessages / limit),
        totalMessages,
        hasMore: skip + messages.length < totalMessages
      }
    });
  } catch (error) {
    console.error('Error fetching thread messages:', error);
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
};

// Delete a message (sender only)
exports.deleteThreadMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user.id;

    const message = await ThreadMessage.findById(messageId);
    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }

    if (message.senderId.toString() !== userId) {
      return res.status(403).json({ error: 'You can only delete your own messages' });
    }

    message.isDeleted = true;
    message.message = 'This message was deleted';
    await message.save();

    res.status(200).json({ success: true, message: 'Message deleted' });
  } catch (error) {
    console.error('Error deleting thread message:', error);
    res.status(500).json({ error: 'Failed to delete message' });
  }
};
