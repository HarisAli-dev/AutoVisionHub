const express = require('express');
const router = express.Router();
const mediaController = require('../controllers/mediaController');
const { protect } = require('../middleware/authMiddleware');

// All routes require authentication
router.use(protect);

router.post('/upload', mediaController.uploadFile);
// Get file with optional transformations
router.get('/get', mediaController.getFile);

// Delete file by URL
router.delete('/delete-by-url', mediaController.deleteFileByUrl);

// Delete multiple files
router.delete('/delete-multiple', mediaController.deleteMultipleFiles);

module.exports = router;
