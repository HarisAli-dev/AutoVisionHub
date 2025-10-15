const express = require('express');
const router = express.Router();
const supportController = require('../controllers/supportController');
const { protect } = require('../middleware/authMiddleware');

// Middleware to protect routes
router.use(protect);
// AI Chatbot endpoint
router.post('/chat', supportController.handleChatbot);

// Get conversation history
router.get('/conversations/:userId', supportController.getConversationHistory);

// Submit feedback on AI response
router.post('/feedback', supportController.submitFeedback);

// Escalate to human support
router.post('/escalate', supportController.escalateToHuman);

module.exports = router;