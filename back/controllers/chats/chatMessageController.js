const Message = require('../../models/chats/chatMessageModel');
const Chat = require('../../models/chats/chatModel');
const Group = require('../../models/groups/groupModel');
const User = require('../../models/users/userModel');
const { getIO } = require('../../config/socket');
const { sendChatMessageNotification } = require('../../services/notificationService');

// Send a new message
exports.sendMessage = async (req, res) => {
  try {
    console.log('Sending message...', req.body);
    console.log('Message type:', req.body.type);
    console.log('Media URL in request:', req.body.mediaUrl ? 'Yes' : 'No');
    const { chatId, content, type, senderName, senderId } = req.body;
    
    // Verify chat exists and senderName is a member
    const chat = await Chat.findById(chatId);
    if (!chat) {
      return res.status(404).json({ message: 'Chat not found' });
    }
    
    // For group chats, check if senderName is a member
    let isGroup = false;
    let recipients = [];
    
    if (chat.isGroup) {
      isGroup = true;
      const group = await Group.findOne({ chatId });
      if (!group || !group.members.includes(senderId)) {
        return res.status(403).json({ message: 'You are not a member of this group' });
      }
      
      // Get all group members for notifications
      recipients = group.members.filter(member => member.toString() !== senderId);
    } else {
      // For direct chats, check if senderName is a participant
      if (!chat.participants.includes(senderId)) {
        return res.status(403).json({ message: 'You are not a participant in this chat' });
      }
      
      // Get the recipient for direct message
      recipients = chat.participants.filter(participant => participant.toString() !== senderId);
    }
    if (!senderName) {
      return res.status(404).json({ message: 'senderName not found' });
    }
    
    const messageData = {
      chatId,
      senderId,
      senderName,
      type,
      content: type === 'text' ? content : null,
      status: 'sent'
    };
    
    // Handle media messages using pre-uploaded mediaUrl from media service
    if (req.body.mediaUrl && ['image', 'video', 'voice', 'file'].includes(type)) {
      messageData.mediaUrl = req.body.mediaUrl;
      
      // Add thumbnailUrl if provided
      if (req.body.thumbnailUrl) {
        messageData.thumbnailUrl = req.body.thumbnailUrl;
      }
      
      // Add duration for voice messages if provided
      if (type === 'voice' && req.body.duration) {
        messageData.duration = parseInt(req.body.duration, 10);
      }
    }
    
    // For call messages
    if (type === 'call') {
      messageData.callType = req.body.callType;
      messageData.duration = req.body.duration ? parseInt(req.body.duration, 10) : 0;
    }
    
    const message = new Message(messageData);
    await message.save();
    
    // Update last message in chat
    chat.lastMessage = message._id;
    await chat.save();
    
    // Get the populated message to include sender details
    const populatedMessage = await Message.findById(message._id);
    
    // Get sender information for notifications
    const sender = await User.findById(senderId);
    
    // Emit socket event for real-time updates
    const io = getIO();
    
    // Emit to chat room (all users in the chat)
    io.to(chatId).emit('newMessage', populatedMessage);
    
    // Send notifications to recipients
    if (sender && recipients.length > 0) {
      for (const recipientId of recipients) {
        // Emit socket notification
        io.to(recipientId.toString()).emit('messageNotification', {
          message: populatedMessage,
          chat: chat
        });
        
        // Send push notification for direct chat
        if (!isGroup) {
          await sendChatMessageNotification(
            recipientId.toString(),
            sender,
            populatedMessage,
            chat
          );
        }
      }
    }
    
    // If it's a group, also emit a group message event
    if (isGroup) {
      io.to(chatId).emit('newGroupMessage', {
        message: populatedMessage,
        chat: chat
      });
    }
    
    res.status(200).json(message);
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ message: 'Failed to send message', error: error.message });
  }
};

// Edit a text message
exports.editMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const { content } = req.body;
    const senderNameId = req.senderName.id;
    
    const message = await Message.findById(messageId);
    
    if (!message) {
      return res.status(404).json({ message: 'Message not found' });
    }
    
    // Only the sender can edit their message
    if (message.senderId.toString() !== senderNameId) {
      return res.status(403).json({ message: 'You can only edit your own messages' });
    }
    
    // Only text messages can be edited
    if (message.type !== 'text') {
      return res.status(400).json({ message: 'Only text messages can be edited' });
    }
    
    // Update the message content
    message.content = content;
    message.updatedAt = new Date();
    await message.save();
    
    // Get the chat to find recipients
    const chat = await Chat.findById(message.chatId);
    if (!chat) {
      return res.status(404).json({ message: 'Chat not found' });
    }
    
    // Emit socket event for real-time updates
    const io = getIO();
    
    // Emit to the chat room that a message was edited
    io.to(message.chatId.toString()).emit('messageEdited', {
      messageId: message._id,
      content: message.content,
      updatedAt: message.updatedAt
    });
    
    res.json(message);
  } catch (error) {
    console.error('Error editing message:', error);
    res.status(500).json({ message: 'Failed to edit message', error: error.message });
  }
};

// Delete a message (soft delete)
exports.deleteMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    
    const message = await Message.findByIdAndDelete(messageId);
    if (!message) {
      return res.status(404).json({ message: 'Message not found' });
    }
    } catch (error) {
      console.error('Error deleting message:', error);
      return res.status(500).json({ message: 'Failed to delete message', error: error.message });
    }
  };

// Update message status (delivered/seen)
exports.updateMessageStatus = async (req, res) => {
  try {
    const { messageId } = req.params;
    const { status } = req.body;
    const senderNameId = req.senderName.id;
    
    if (!['delivered', 'seen'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status value' });
    }
    
    const message = await Message.findById(messageId);
    
    if (!message) {
      return res.status(404).json({ message: 'Message not found' });
    }
    
    // Only update status for messages not sent by the senderName
    if (message.senderId.toString() === senderNameId) {
      return res.status(400).json({ message: 'Cannot update status of your own messages' });
    }
    
    message.status = status;
    await message.save();
    
    // Get the sender of the original message
    const senderId = message.senderId;
    
    // Notify the original sender that their message was seen/delivered
    const io = getIO();
    io.to(senderId.toString()).emit('messageStatusUpdated', {
      messageId: message._id,
      status: status,
      updatedBy: senderNameId
    });
    
    res.json(message);
  } catch (error) {
    console.error('Error updating message status:', error);
    res.status(500).json({ message: 'Failed to update message status', error: error.message });
  }
};
