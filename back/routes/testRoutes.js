const express = require('express');
const router = express.Router();
const { protect } = require('../../middleware/authMiddleware');
const { sendNotificationToUser } = require('../../services/notificationService');

// Test notification endpoint
router.post('/test-notification', protect, async (req, res) => {
  try {
    const { title, body, recipientId } = req.body;
    
    if (!title || !body || !recipientId) {
      return res.status(400).json({ 
        message: 'Title, body, and recipientId are required' 
      });
    }

    const notification = { title, body };
    const data = { 
      type: 'test',
      route: '/communityMemberHome' 
    };

    const result = await sendNotificationToUser(recipientId, notification, data);
    
    res.status(200).json({ 
      message: 'Test notification sent successfully',
      result 
    });
  } catch (error) {
    console.error('Error sending test notification:', error);
    res.status(500).json({ 
      message: 'Failed to send test notification', 
      error: error.message 
    });
  }
});

module.exports = router;