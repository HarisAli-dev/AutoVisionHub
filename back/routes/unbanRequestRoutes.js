// routes/unbanRequestRoutes.js
const express = require('express');
const router = express.Router();
const unbanRequestController = require('../controllers/unbanRequestController');
const { protect, admin } = require('../middleware/authMiddleware');

// Unban request creation (no auth required - for banned users)
router.post('/create', unbanRequestController.createUnbanRequest);

// User routes (protected)
router.use(protect);
router.get('/my-request', unbanRequestController.getUserUnbanRequest);

// Admin routes
router.get('/all', admin, unbanRequestController.getAllUnbanRequests);
router.patch('/review/:requestId', admin, unbanRequestController.reviewUnbanRequest);

module.exports = router;
