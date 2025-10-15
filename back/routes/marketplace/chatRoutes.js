const express = require('express');
const router = express.Router();
const { protect } = require('../../middleware/authMiddleware');
const {
  createOrGetChat,
  getUserChats,
  getChatMessages,
  sendMessage,
  sendOfferMessage,
  deleteMessage,
  markChatAsRead
} = require('../../controllers/marketplace/marketplaceChatController');

// All routes require authentication
router.use(protect);

router.post('/listing/:listingId', createOrGetChat); // Create or get chat for a listing
router.get('/my/chats', getUserChats); // Get user's chats
router.get('/:chatId/messages', getChatMessages); // Get chat messages
router.post('/:chatId/message', sendMessage); // Send a message
router.post('/:chatId/offer', sendOfferMessage); // Send offer message
router.delete('/message/:messageId', deleteMessage); // Delete a message
router.put('/:chatId/read', markChatAsRead); // Mark chat as read

module.exports = router;
