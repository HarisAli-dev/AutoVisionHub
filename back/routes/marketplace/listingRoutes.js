const express = require('express');
const router = express.Router();
const { protect, optionalAuth } = require('../../middleware/authMiddleware');
const {
  createListing,
  getAllListings,
  getListingById,
  getMyListings,
  updateListing,
  deleteListing,
  toggleFavorite,
  getFavoriteListings,
  getRecentlyViewedItems,
  getRecentlyViewedListings
} = require('../../controllers/marketplace/listingController');

// Public routes
router.get('/', getAllListings); // Get all listings with filters

// Protected routes - specific routes must come before parameterized routes
router.use(protect); // All routes below require authentication

router.post('/', createListing); // Create new listing
router.get('/my/listings', getMyListings); // Get user's own listings
router.get('/my/favorites', getFavoriteListings); // Get user's favorite listings
router.get('/recently-viewed', getRecentlyViewedItems); // Get user's recently viewed items (old)
router.get('/my/recently-viewed', getRecentlyViewedListings); // Get user's recently viewed items with timestamps
router.get('/:id', optionalAuth, getListingById); // Get single listing by ID (must be after specific routes)
router.put('/:id', updateListing); // Update listing
router.delete('/:id', deleteListing); // Delete listing
router.post('/:listingId/favorite', toggleFavorite); // Toggle favorite

module.exports = router;
