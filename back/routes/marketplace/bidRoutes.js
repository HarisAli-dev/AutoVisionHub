const express = require('express');
const router = express.Router();
const { protect } = require('../../middleware/authMiddleware');
const {
  placeBid,
  getListingBids,
  getUserBids,
  cancelBid,
  getAuctionStats
} = require('../../controllers/marketplace/bidController');

// All routes require authentication
router.use(protect);

router.post('/:listingId', placeBid); // Place a bid on a listing
router.get('/listing/:listingId', getListingBids); // Get bids for a listing
router.get('/my/bids', getUserBids); // Get user's bids
router.delete('/:bidId', cancelBid); // Cancel a bid
router.get('/stats/:listingId', getAuctionStats); // Get auction statistics

module.exports = router;
