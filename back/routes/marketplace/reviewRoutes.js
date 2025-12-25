const express = require('express');
const router = express.Router();
const reviewController = require('../../controllers/marketplace/reviewController');
const { protect } = require('../../middleware/authMiddleware');

// Add or update review for a listing
router.post('/listing/:listingId', protect, reviewController.addOrUpdateReview);

// Get reviews for a listing (public)
router.get('/listing/:listingId', reviewController.getListingReviews);

// Delete a review
router.delete('/:reviewId', protect, reviewController.deleteReview);

module.exports = router;
