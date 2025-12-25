const express = require('express');
const router = express.Router();
const threadController = require('../../controllers/groups/threadController');
const threadMessageController = require('../../controllers/groups/threadMessageController');
const { protect } = require('../../middleware/authMiddleware');

// Thread routes
router.post('/create', protect, threadController.createThread);
router.get('/all', protect, threadController.getAllThreads);
router.get('/user', protect, threadController.getUserThreads);
router.get('/:threadId', protect, threadController.getThreadDetails);
router.post('/:threadId/join', protect, threadController.joinThread);
router.post('/:threadId/leave', protect, threadController.leaveThread);
router.delete('/:threadId', protect, threadController.deleteThread);
// Thread message routes
router.post('/message/send', protect, threadMessageController.sendThreadMessage);
router.get('/:threadId/messages', protect, threadMessageController.getThreadMessages);
router.delete('/message/:messageId', protect, threadMessageController.deleteThreadMessage);
module.exports = router;
