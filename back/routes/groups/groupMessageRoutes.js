const express = require('express');
const router = express.Router();
const {
  sendMessage,
  getGroupMessages,
  deleteGroupMessage,
  editGroupMessage,
  markGroupAsRead,
} = require('../../controllers/groups/groupMessageController');
const { protect } = require('../../middleware/authMiddleware');

// All routes require authentication
router.use(protect);

// Message routes
router.post('/sendMessage', sendMessage);
router.get('/:groupId/messages', getGroupMessages);
router.delete('/message/:messageId', deleteGroupMessage);
router.patch('/message/:messageId', editGroupMessage);
router.patch('/:groupId/read', markGroupAsRead);

module.exports = router;
