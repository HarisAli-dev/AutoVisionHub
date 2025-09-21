// routes/messageRoutes.js
const express = require('express');
const router = express.Router();
const chatMessageController = require('../../controllers/chats/chatMessageController');
const { protect } = require('../../middleware/authMiddleware');

// All routes are protected - requires authentication
router.use(protect);

// Send a message - files are now handled via the media upload endpoint
router.post('/send', chatMessageController.sendMessage);

// Edit a text message
router.put('/:messageId/edit', chatMessageController.editMessage);

// Delete a message (soft delete)
router.delete('/:messageId', chatMessageController.deleteMessage);

// Update message status (delivered/seen)
router.patch('/:messageId/status', chatMessageController.updateMessageStatus);

module.exports = router;