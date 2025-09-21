// routes/authRoutes.js
const express = require('express');
const router = express.Router();
const authController = require('../../controllers/users/authController');
const { protect} = require('../../middleware/authMiddleware');

router.post('/register', authController.register);
router.post('/login', authController.login);

router.get('/checkTokenExpiry/:token', authController.checkTokenExpiry);

router.use(protect); // Protect all routes below this middleware
router.delete('/delete/:userId', authController.deleteProfile);

module.exports = router;
