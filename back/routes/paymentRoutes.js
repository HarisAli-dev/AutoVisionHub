const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);
router.post('/create-payment-intent', paymentController.createPaymentIntent);

module.exports = router;
