// routes/authRoutes.js
const express = require('express');
const router = express.Router();
const authController = require('../../controllers/users/authController');
const { protect} = require('../../middleware/authMiddleware');
const { checkBanned } = require('../../middleware/bannedUserMiddleware');

router.post('/register', authController.register);
router.post('/login', checkBanned, authController.login);

router.get('/checkTokenExpiry/:token', authController.checkTokenExpiry);

router.use(protect); // Protect all routes below this middleware
router.delete('/delete/:userId', authController.deleteProfile);
router.put('/fcm-token', authController.updateFCMToken);
router.post('/logout', authController.logout);

module.exports = router;
