const express = require('express');
const { zegoChatbotController } = require('../controllers/zegoChatbotController');
const { protect } = require('../middleware/authMiddleware');
const router = express.Router();

// Token generation endpoint (requires authentication)
router.get('/token', protect, zegoChatbotController.generateToken);

// AI Agent registration (admin only - can add admin middleware)
router.post('/chatbot/register', protect, zegoChatbotController.registerAgent);

// Chatbot session management
router.post('/chatbot/start', protect, zegoChatbotController.startChatbot);
router.post('/chatbot/stop', protect, zegoChatbotController.stopChatbot);

// Chatbot messaging
router.post('/chatbot/message', protect, zegoChatbotController.sendMessage);

// Chatbot status and monitoring
router.get('/chatbot/status/:roomId', protect, zegoChatbotController.getChatbotStatus);
router.get('/chatbot/active', protect, zegoChatbotController.getActiveChatbots);

// Chatbot configuration
router.put('/chatbot/config', protect, zegoChatbotController.updateChatbotConfig);

module.exports = router;
