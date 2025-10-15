const express = require('express');
const router = express.Router();
const { protect } = require('../../middleware/authMiddleware');
const {
  createListing,
  getAllListings,
  getListingById,
  getMyListings,
  updateListing,
  deleteListing,
  toggleFavorite,
  getFavoriteListings
} = require('../../controllers/marketplace/listingController');

// Public routes
router.get('/', getAllListings); // Get all listings with filters
router.get('/:id', getListingById); // Get single listing by ID

// Protected routes
router.use(protect); // All routes below require authentication

router.post('/', createListing); // Create new listing
router.get('/my/listings', getMyListings); // Get user's own listings
router.put('/:id', updateListing); // Update listing
router.delete('/:id', deleteListing); // Delete listing
router.post('/:listingId/favorite', toggleFavorite); // Toggle favorite
router.get('/my/favorites', getFavoriteListings); // Get user's favorite listings

module.exports = router;
