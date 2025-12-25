const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { protect } = require('../middleware/authMiddleware');

// Payment profile routes (protected)
router.use(protect);
router.post('/profile/create', paymentController.createPaymentProfile);
router.get('/profile', paymentController.getPaymentProfile);
router.put('/profile/update', paymentController.updatePaymentProfile);
router.post('/profile/payout-method', paymentController.addPayoutMethod);
router.delete('/profile/payout-method/:bankAccountId', paymentController.removePayoutMethod);
router.get('/profile/onboarding-link', paymentController.generateOnboardingLink);

// Transaction routes (protected)
router.post('/create-payment-intent', paymentController.createPaymentIntent);
router.get('/transactions', paymentController.getTransactionHistory);
router.get('/earnings', paymentController.getEarningsSummary);

// Webhook route (not protected - Stripe calls this)
router.post('/webhook', express.raw({ type: 'application/json' }), paymentController.handleStripeWebhook);

module.exports = router;
