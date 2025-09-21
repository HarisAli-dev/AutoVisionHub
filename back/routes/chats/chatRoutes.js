// routes/chatRoutes.js
const express = require('express');
const router = express.Router();
const chatController = require('../../controllers/chats/chatController');
const { protect } = require('../../middleware/authMiddleware');

// Protect all routes
router.use(protect);

// Get all chats for the logged in user
router.get('/getChats', chatController.getChatsForUser);

// Create a new chat
router.post('/createChat', chatController.createNewChat);

// Get messages for a specific chat
router.get('/:chatId/messages', chatController.getChatMessages);

// Get  chat between users
router.get('/:chatId', chatController.getChatBetweenUsers);

// Delete a chat
router.delete('/:chatId', chatController.deleteChatBetweenUsers);

// Mark chat as read
router.patch('/:chatId/read', chatController.markChatAsRead);

module.exports = router;
