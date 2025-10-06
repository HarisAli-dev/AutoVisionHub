const GroupMessage = require('../../models/groups/groupMessageModel');
const Group = require('../../models/groups/groupModel');
const User = require('../../models/users/userModel');
const Poll = require('../../models/groups/pollModel');
const { getIO } = require('../../config/socket');
const { sendGroupMessageNotification } = require('../../services/notificationService');

// Send a message to group
const sendMessage = async (req, res) => {
  try {
    const {
      groupId,
      type,
      content,
      mediaUrl,
      thumbnailUrl,
      duration,
      callType,
      pollId
    } = req.body;
    
    const senderId = req.user.id;
    const senderName = req.user.name;

    // Validate group exists and user is a participant
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    if (!group.participants.includes(senderId)) {
      return res.status(403).json({ error: 'You are not a member of this group' });
    }

    // Create the message
    const message = new GroupMessage({
      groupId,
      senderId,
      senderName,
      type,
      content,
      mediaUrl,
      thumbnailUrl,
      duration,
      callType,
      status: 'sent'
    });

    // If it's a poll message, link to the poll
    if (type === 'poll' && pollId) {
      message.pollId = pollId;
    }

    await message.save();

    // Update group's last message and unread counts
    group.lastMessage = message._id;
    
    // Increment unread count for all participants except sender
    group.participants.forEach(participantId => {
      if (participantId.toString() !== senderId) {
        const currentCount = group.unreadCounts.get(participantId.toString()) || 0;
        group.unreadCounts.set(participantId.toString(), currentCount + 1);
      }
    });

    await group.save();

    // Get sender information for notifications
    const sender = await User.findById(senderId);

    // Emit socket events for real-time updates
    const io = getIO();
    
    // Emit to all group members
    io.to(groupId).emit('newGroupMessage', {
      message,
      group
    });

    // Send push notifications to all group members except sender
    if (sender) {
      const recipients = group.participants.filter(participantId => 
        participantId.toString() !== senderId
      );

      for (const recipientId of recipients) {
        // Emit socket notification
        io.to(recipientId.toString()).emit('groupMessageNotification', {
          message,
          group,
          sender
        });

        // Send push notification
        await sendGroupMessageNotification(
          recipientId.toString(),
          sender,
          message,
          group
        );
      }
    }

    res.status(201).json({ message });
  } catch (error) {
    console.error('Error sending group message:', error);
    res.status(500).json({ error: 'Failed to send message' });
  }
};

// Get group messages with pagination
const getGroupMessages = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    const userId = req.user.id;

    // Validate group exists and user is a participant
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    if (!group.participants.includes(userId)) {
      return res.status(403).json({ error: 'You are not a member of this group' });
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const messages = await GroupMessage.find({
      groupId,
      isDeleted: false,
      $nor: [{ deletedFor: userId }]
    })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const totalMessages = await GroupMessage.countDocuments({
      groupId,
      isDeleted: false,
      $nor: [{ deletedFor: userId }]
    });

    res.status(200).json({
      messages: messages, // Reverse to show oldest first
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalMessages,
        pages: Math.ceil(totalMessages / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Error getting group messages:', error);
    res.status(500).json({ error: 'Failed to get messages' });
  }
};

// Delete a group message
const deleteGroupMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user.id;

    const message = await GroupMessage.findByIdAndDelete(messageId);
    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }
    } catch (error) {
    console.error('Error deleting group message:', error);
    res.status(500).json({ error: 'Failed to delete message' });
  }
};

// Edit a group message
const editGroupMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const { content } = req.body;
    const userId = req.user.id;

    const message = await GroupMessage.findById(messageId);
    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }

    // Check if user is the sender
    if (message.senderId.toString() !== userId) {
      return res.status(403).json({ error: 'You can only edit your own messages' });
    }

    // Only allow editing text messages
    if (message.type !== 'text') {
      return res.status(400).json({ error: 'Only text messages can be edited' });
    }

    // Update message content
    message.content = content;
    message.updatedAt = new Date();
    await message.save();

    await message.populate('senderId', 'name email profileImageUrl');

    res.status(200).json({ message });
  } catch (error) {
    console.error('Error editing group message:', error);
    res.status(500).json({ error: 'Failed to edit message' });
  }
};

// Mark group as read
const markGroupAsRead = async (req, res) => {
  try {
    const { groupId } = req.params;
    const userId = req.user.id;

    // Validate group exists and user is a participant
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    if (!group.participants.includes(userId)) {
      return res.status(403).json({ error: 'You are not a member of this group' });
    }

    // Reset unread count for this user
    group.unreadCounts.set(userId, 0);
    await group.save();

    // Mark all messages as seen for this user
    await GroupMessage.updateMany(
      {
        groupId,
        senderId: { $ne: userId },
        status: { $in: ['sent', 'delivered'] }
      },
      { status: 'seen' }
    );

    res.status(200).json({ success: true, message: 'Group marked as read' });
  } catch (error) {
    console.error('Error marking group as read:', error);
    res.status(500).json({ error: 'Failed to mark group as read' });
  }
};




module.exports = {
  sendMessage,
  getGroupMessages,
  deleteGroupMessage,
  editGroupMessage,
  markGroupAsRead,
};
