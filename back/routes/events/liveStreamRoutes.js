const express = require('express');
const { liveStreamController } = require('../../controllers/events/liveStreamController');
const { protect } = require('../../middleware/authMiddleware');
const router = express.Router();

// All routes require authentication
router.use(protect);

// Start a new live stream for an event
router.post('/start', liveStreamController.startLiveStream);

// Join an existing live stream
router.post('/join/:roomId', liveStreamController.joinLiveStream);

// Stop a live stream
router.put('/stop/:roomId', liveStreamController.stopLiveStream);

// Get live stream status for an event
router.get('/status/:eventId', liveStreamController.getLiveStreamStatus);

// Leave a live stream (for viewers)
router.put('/leave/:roomId', liveStreamController.leaveLiveStream);

// Get live stream analytics (for hosts)
router.get('/analytics/:roomId', liveStreamController.getLiveStreamAnalytics);

// Record engagement event (likes, comments, etc.)
router.post('/engagement/:roomId', liveStreamController.recordEngagementEvent);

module.exports = router;