const MarketplaceChat = require('../../models/marketplace/marketplaceChatModel');
const MarketplaceMessage = require('../../models/marketplace/marketplaceMessageModel');
const Listing = require('../../models/marketplace/listingModel');
const User = require('../../models/users/userModel');
const mongoose = require('mongoose');

// Create or get existing chat for a listing
exports.createOrGetChat = async (req, res) => {
  try {
    const { listingId } = req.params;
    const userId = req.user.id;

    // Get the listing
    const listing = await Listing.findById(listingId);
    if (!listing) {
      return res.status(404).json({
        success: false,
        message: 'Listing not found'
      });
    }

    // Check if user is not the seller
    if (listing.seller.toString() === userId) {
      return res.status(400).json({
        success: false,
        message: 'You cannot chat with yourself'
      });
    }

    // Check if chat already exists
    let chat = await MarketplaceChat.findOne({
      listing: listingId,
      participants: { $all: [userId, listing.seller] }
    }).populate('participants', 'name profileImageUrl');

    if (!chat) {
      // Create new chat
      chat = new MarketplaceChat({
        listing: listingId,
        participants: [userId, listing.seller]
      });

      await chat.save();
      await chat.populate('participants', 'name profileImageUrl');
    }

    // Populate listing details
    await chat.populate('listing', 'title price images seller');

    res.status(200).json({
      success: true,
      data: chat
    });

  } catch (error) {
    console.error('Error creating/getting chat:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get user's chats
exports.getUserChats = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const chats = await MarketplaceChat.find({
      participants: userId,
      isActive: true
    })
      .populate('participants', 'name profileImageUrl')
      .populate('listing', 'title price images')
      .sort({ updatedAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await MarketplaceChat.countDocuments({
      participants: userId,
      isActive: true
    });

    res.status(200).json({
      success: true,
      data: {
        chats,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
          totalItems: total,
          itemsPerPage: parseInt(limit)
        }
      }
    });

  } catch (error) {
    console.error('Error fetching user chats:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get chat messages
exports.getChatMessages = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user.id;
    const { page = 1, limit = 50 } = req.query;

    // Verify user is participant in the chat
    const chat = await MarketplaceChat.findById(chatId);
    if (!chat) {
      return res.status(404).json({
        success: false,
        message: 'Chat not found'
      });
    }

    if (!chat.participants.includes(userId)) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to view this chat'
      });
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const messages = await MarketplaceMessage.find({
      chat: chatId,
      isDeleted: false
    })
      .populate('sender', 'name profileImageUrl')
      .populate('replyTo', 'content sender')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await MarketplaceMessage.countDocuments({
      chat: chatId,
      isDeleted: false
    });

    // Mark messages as read for this user
    await MarketplaceMessage.updateMany(
      {
        chat: chatId,
        sender: { $ne: userId },
        'readBy.user': { $ne: userId }
      },
      {
        $push: {
          readBy: {
            user: userId,
            readAt: new Date()
          }
        }
      }
    );

    res.status(200).json({
      success: true,
      data: {
        messages: messages.reverse(), // Return in chronological order
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
          totalItems: total,
          itemsPerPage: parseInt(limit)
        }
      }
    });

  } catch (error) {
    console.error('Error fetching chat messages:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Send a message
exports.sendMessage = async (req, res) => {
  try {
    const { chatId } = req.params;
    const { content, messageType = 'text', imageUrl, replyTo } = req.body;
    const userId = req.user.id;

    // Verify user is participant in the chat
    const chat = await MarketplaceChat.findById(chatId);
    if (!chat) {
      return res.status(404).json({
        success: false,
        message: 'Chat not found'
      });
    }

    if (!chat.participants.includes(userId)) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to send messages in this chat'
      });
    }

    // Validate content based on message type
    if (messageType === 'text' && !content) {
      return res.status(400).json({
        success: false,
        message: 'Message content is required'
      });
    }

    if (messageType === 'image' && !imageUrl) {
      return res.status(400).json({
        success: false,
        message: 'Image URL is required for image messages'
      });
    }

    // Create new message
    const newMessage = new MarketplaceMessage({
      chat: chatId,
      sender: userId,
      content: content || '',
      messageType,
      imageUrl,
      replyTo
    });

    const savedMessage = await newMessage.save();

    // Update chat's last message
    chat.lastMessage = {
      content: content || 'Image',
      sender: userId,
      timestamp: new Date(),
      messageType
    };

    // Reset unread count for sender, increment for other participants
    chat.unreadCounts = chat.unreadCounts.map(unread => {
      if (unread.user.toString() === userId) {
        return { ...unread, count: 0 };
      } else {
        return { ...unread, count: (unread.count || 0) + 1 };
      }
    });

    await chat.save();

    // Populate message details
    const populatedMessage = await MarketplaceMessage.findById(savedMessage._id)
      .populate('sender', 'name profileImageUrl')
      .populate('replyTo', 'content sender');

    res.status(201).json({
      success: true,
      message: 'Message sent successfully',
      data: populatedMessage
    });

  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Send offer message
exports.sendOfferMessage = async (req, res) => {
  try {
    const { chatId } = req.params;
    const { amount, message } = req.body;
    const userId = req.user.id;

    // Verify user is participant in the chat
    const chat = await MarketplaceChat.findById(chatId);
    if (!chat) {
      return res.status(404).json({
        success: false,
        message: 'Chat not found'
      });
    }

    if (!chat.participants.includes(userId)) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to send messages in this chat'
      });
    }

    // Get listing details
    const listing = await Listing.findById(chat.listing);
    if (!listing) {
      return res.status(404).json({
        success: false,
        message: 'Listing not found'
      });
    }

    // Validate offer amount
    if (amount >= listing.price) {
      return res.status(400).json({
        success: false,
        message: 'Offer must be less than the listing price'
      });
    }

    // Create offer message
    const newMessage = new MarketplaceMessage({
      chat: chatId,
      sender: userId,
      content: message || `I'm offering PKR ${amount} for this item`,
      messageType: 'offer',
      offerData: {
        amount
      }
    });

    const savedMessage = await newMessage.save();

    // Update chat's last message
    chat.lastMessage = {
      content: `Offer: PKR ${amount}`,
      sender: userId,
      timestamp: new Date(),
      messageType: 'offer'
    };

    // Reset unread count for sender, increment for other participants
    chat.unreadCounts = chat.unreadCounts.map(unread => {
      if (unread.user.toString() === userId) {
        return { ...unread, count: 0 };
      } else {
        return { ...unread, count: (unread.count || 0) + 1 };
      }
    });

    await chat.save();

    // Populate message details
    const populatedMessage = await MarketplaceMessage.findById(savedMessage._id)
      .populate('sender', 'name profileImageUrl');

    res.status(201).json({
      success: true,
      message: 'Offer message sent successfully',
      data: populatedMessage
    });

  } catch (error) {
    console.error('Error sending offer message:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Delete a message
exports.deleteMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user.id;

    const message = await MarketplaceMessage.findById(messageId);
    if (!message) {
      return res.status(404).json({
        success: false,
        message: 'Message not found'
      });
    }

    // Verify user is the sender
    if (message.sender.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to delete this message'
      });
    }

    // Soft delete
    message.isDeleted = true;
    message.deletedAt = new Date();
    message.deletedBy = userId;
    await message.save();

    res.status(200).json({
      success: true,
      message: 'Message deleted successfully'
    });

  } catch (error) {
    console.error('Error deleting message:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Mark chat as read
exports.markChatAsRead = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user.id;

    // Verify user is participant in the chat
    const chat = await MarketplaceChat.findById(chatId);
    if (!chat) {
      return res.status(404).json({
        success: false,
        message: 'Chat not found'
      });
    }

    if (!chat.participants.includes(userId)) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to mark this chat as read'
      });
    }

    // Mark all messages in this chat as read for this user
    await MarketplaceMessage.updateMany(
      {
        chat: chatId,
        sender: { $ne: userId },
        'readBy.user': { $ne: userId }
      },
      {
        $push: {
          readBy: {
            user: userId,
            readAt: new Date()
          }
        }
      }
    );

    // Reset unread count for this user
    chat.unreadCounts = chat.unreadCounts.map(unread => {
      if (unread.user.toString() === userId) {
        return { ...unread, count: 0 };
      }
      return unread;
    });

    await chat.save();

    res.status(200).json({
      success: true,
      message: 'Chat marked as read'
    });

  } catch (error) {
    console.error('Error marking chat as read:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};
