// routes/userRoutes.js
const express = require('express');
const router = express.Router();
const userController = require('../../controllers/users/userController');
const { protect } = require('../../middleware/authMiddleware');

// Protected routes - require authentication
router.use(protect);
// Get users that a user has not chatted with yet
router.get('/new-chat-users/:userId', userController.chatWithNewUserList);

// Get user profile
router.get('/profile', userController.getProfile);

// Update user profile
router.put('/update', userController.updateProfile);

// Change user password
router.put('/change-password', userController.changePassword);
// Search for users by name or email
router.get('/search/:query', userController.searchUser);

//get all users
router.get('/all', userController.getAllUsers);

// Admin only routes - Delete and Ban users
router.delete('/delete/:userId', userController.deleteUser);
router.put('/ban/:userId', userController.banUser);

module.exports = router;
