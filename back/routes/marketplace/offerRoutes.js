const express = require('express');
const router = express.Router();
const { protect } = require('../../middleware/authMiddleware');
const {
  makeOffer,
  getListingOffers,
  getUserOffers,
  acceptOffer,
  rejectOffer,
  makeCounterOffer,
  acceptCounterOffer,
  cancelOffer
} = require('../../controllers/marketplace/offerController');

// All routes require authentication
router.use(protect);

router.post('/:listingId', makeOffer); // Make an offer on a listing
router.get('/listing/:listingId', getListingOffers); // Get offers for a listing (seller's view)
router.get('/my/offers', getUserOffers); // Get user's offers (buyer's view)
router.put('/:offerId/accept', acceptOffer); // Accept an offer
router.put('/:offerId/reject', rejectOffer); // Reject an offer
router.put('/:offerId/counter', makeCounterOffer); // Make a counter offer
router.put('/:offerId/accept-counter', acceptCounterOffer); // Accept counter offer
router.delete('/:offerId', cancelOffer); // Cancel an offer

module.exports = router;
