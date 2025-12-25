const express = require('express');
const multer = require('multer');
const { liveStreamController } = require('../../controllers/events/liveStreamController');
const { protect } = require('../../middleware/authMiddleware');
const router = express.Router();

// Configure multer for video upload
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/recordings/');
  },
  filename: (req, file, cb) => {
    cb(null, `rec_${Date.now()}_${file.originalname}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 500 * 1024 * 1024 }, // 500MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('video/')) {
      cb(null, true);
    } else {
      cb(new Error('Only video files are allowed'));
    }
  }
});

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

// Upload recording
router.post('/recording/upload/:roomId', upload.single('video'), liveStreamController.uploadRecording);

// Get recording
router.get('/recording/:roomId', liveStreamController.getRecording);

module.exports = router;