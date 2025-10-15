const Offer = require('../../models/marketplace/offerModel');
const Listing = require('../../models/marketplace/listingModel');
const User = require('../../models/users/userModel');
const mongoose = require('mongoose');

// Make an offer on a listing
exports.makeOffer = async (req, res) => {
  try {
    const { listingId } = req.params;
    const { amount, message } = req.body;
    const userId = req.user.id;

    // Validate required fields
    if (!amount) {
      return res.status(400).json({
        success: false,
        message: 'Offer amount is required'
      });
    }

    // Get the listing
    const listing = await Listing.findById(listingId);
    if (!listing) {
      return res.status(404).json({
        success: false,
        message: 'Listing not found'
      });
    }

    // Check if listing is negotiable
    if (!listing.isNegotiable) {
      return res.status(400).json({
        success: false,
        message: 'This listing is not negotiable'
      });
    }

    // Check if listing is active
    if (listing.status !== 'active' || !listing.isActive) {
      return res.status(400).json({
        success: false,
        message: 'Listing is no longer active'
      });
    }

    // Check if user is not the seller
    if (listing.seller.toString() === userId) {
      return res.status(400).json({
        success: false,
        message: 'You cannot make an offer on your own listing'
      });
    }

    // Validate offer amount
    if (amount >= listing.price) {
      return res.status(400).json({
        success: false,
        message: 'Offer must be less than the listing price'
      });
    }

    if (listing.minimumOffer && amount < listing.minimumOffer) {
      return res.status(400).json({
        success: false,
        message: `Minimum offer is PKR ${listing.minimumOffer}`
      });
    }

    // Check if there's already a pending offer from this user
    const existingOffer = await Offer.findOne({
      listing: listingId,
      buyer: userId,
      status: 'pending'
    });

    if (existingOffer) {
      return res.status(400).json({
        success: false,
        message: 'You already have a pending offer on this listing'
      });
    }

    // Create new offer
    const newOffer = new Offer({
      listing: listingId,
      buyer: userId,
      seller: listing.seller,
      amount,
      message
    });

    const savedOffer = await newOffer.save();

    // Populate offer details
    const populatedOffer = await Offer.findById(savedOffer._id)
      .populate('buyer', 'name profileImageUrl')
      .populate('seller', 'name profileImageUrl')
      .populate('listing', 'title price images');

    res.status(201).json({
      success: true,
      message: 'Offer made successfully',
      data: populatedOffer
    });

  } catch (error) {
    console.error('Error making offer:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get offers for a listing (seller's view)
exports.getListingOffers = async (req, res) => {
  try {
    const { listingId } = req.params;
    const userId = req.user.id;
    const { page = 1, limit = 20, status } = req.query;

    // Verify user owns the listing
    const listing = await Listing.findById(listingId);
    if (!listing) {
      return res.status(404).json({
        success: false,
        message: 'Listing not found'
      });
    }

    if (listing.seller.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to view offers for this listing'
      });
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const query = { listing: listingId };

    if (status) {
      query.status = status;
    }

    const offers = await Offer.find(query)
      .populate('buyer', 'name profileImageUrl phoneNumber')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Offer.countDocuments(query);

    res.status(200).json({
      success: true,
      data: {
        offers,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
          totalItems: total,
          itemsPerPage: parseInt(limit)
        }
      }
    });

  } catch (error) {
    console.error('Error fetching listing offers:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get user's offers (buyer's view)
exports.getUserOffers = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20, status } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const query = { buyer: userId };

    if (status) {
      query.status = status;
    }

    const offers = await Offer.find(query)
      .populate('seller', 'name profileImageUrl phoneNumber')
      .populate('listing', 'title price images')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Offer.countDocuments(query);

    res.status(200).json({
      success: true,
      data: {
        offers,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
          totalItems: total,
          itemsPerPage: parseInt(limit)
        }
      }
    });

  } catch (error) {
    console.error('Error fetching user offers:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Accept an offer
exports.acceptOffer = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { offerId } = req.params;
    const { responseMessage } = req.body;
    const userId = req.user.id;

    const offer = await Offer.findById(offerId).session(session);
    if (!offer) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({
        success: false,
        message: 'Offer not found'
      });
    }

    // Verify user is the seller
    if (offer.seller.toString() !== userId) {
      await session.abortTransaction();
      session.endSession();
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to accept this offer'
      });
    }

    if (offer.status !== 'pending') {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'This offer is no longer pending'
      });
    }

    // Update offer status
    offer.status = 'accepted';
    offer.responseMessage = responseMessage;
    offer.respondedBy = userId;
    offer.respondedAt = new Date();
    await offer.save({ session });

    // Update listing status
    const listing = await Listing.findById(offer.listing).session(session);
    listing.status = 'sold';
    listing.soldTo = offer.buyer;
    listing.soldAt = new Date();
    listing.soldPrice = offer.amount;
    await listing.save({ session });

    // Reject all other pending offers for this listing
    await Offer.updateMany(
      { 
        listing: offer.listing, 
        _id: { $ne: offerId }, 
        status: 'pending' 
      },
      { 
        $set: { 
          status: 'rejected',
          responseMessage: 'Offer was accepted by another buyer',
          respondedBy: userId,
          respondedAt: new Date()
        }
      }
    ).session(session);

    await session.commitTransaction();
    session.endSession();

    // Populate offer details
    const populatedOffer = await Offer.findById(offerId)
      .populate('buyer', 'name profileImageUrl phoneNumber')
      .populate('seller', 'name profileImageUrl phoneNumber')
      .populate('listing', 'title price images');

    res.status(200).json({
      success: true,
      message: 'Offer accepted successfully',
      data: populatedOffer
    });

  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    console.error('Error accepting offer:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Reject an offer
exports.rejectOffer = async (req, res) => {
  try {
    const { offerId } = req.params;
    const { responseMessage } = req.body;
    const userId = req.user.id;

    const offer = await Offer.findById(offerId);
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offer not found'
      });
    }

    // Verify user is the seller
    if (offer.seller.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to reject this offer'
      });
    }

    if (offer.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'This offer is no longer pending'
      });
    }

    // Update offer status
    offer.status = 'rejected';
    offer.responseMessage = responseMessage;
    offer.respondedBy = userId;
    offer.respondedAt = new Date();
    await offer.save();

    res.status(200).json({
      success: true,
      message: 'Offer rejected successfully'
    });

  } catch (error) {
    console.error('Error rejecting offer:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Make a counter offer
exports.makeCounterOffer = async (req, res) => {
  try {
    const { offerId } = req.params;
    const { amount, message } = req.body;
    const userId = req.user.id;

    if (!amount) {
      return res.status(400).json({
        success: false,
        message: 'Counter offer amount is required'
      });
    }

    const offer = await Offer.findById(offerId);
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offer not found'
      });
    }

    // Verify user is the seller
    if (offer.seller.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to make a counter offer'
      });
    }

    if (offer.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'This offer is no longer pending'
      });
    }

    // Update offer with counter offer details
    offer.status = 'countered';
    offer.counterOffer = {
      amount,
      message,
      counterOfferBy: userId,
      counterOfferAt: new Date()
    };
    offer.responseMessage = message;
    offer.respondedBy = userId;
    offer.respondedAt = new Date();
    await offer.save();

    // Populate offer details
    const populatedOffer = await Offer.findById(offerId)
      .populate('buyer', 'name profileImageUrl phoneNumber')
      .populate('seller', 'name profileImageUrl phoneNumber')
      .populate('listing', 'title price images');

    res.status(200).json({
      success: true,
      message: 'Counter offer made successfully',
      data: populatedOffer
    });

  } catch (error) {
    console.error('Error making counter offer:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Accept counter offer
exports.acceptCounterOffer = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { offerId } = req.params;
    const userId = req.user.id;

    const offer = await Offer.findById(offerId).session(session);
    if (!offer) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({
        success: false,
        message: 'Offer not found'
      });
    }

    // Verify user is the buyer
    if (offer.buyer.toString() !== userId) {
      await session.abortTransaction();
      session.endSession();
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to accept this counter offer'
      });
    }

    if (offer.status !== 'countered') {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'This offer is not available for counter offer acceptance'
      });
    }

    // Update offer with counter offer amount
    offer.amount = offer.counterOffer.amount;
    offer.status = 'accepted';
    offer.responseMessage = 'Counter offer accepted';
    offer.respondedBy = userId;
    offer.respondedAt = new Date();
    await offer.save({ session });

    // Update listing status
    const listing = await Listing.findById(offer.listing).session(session);
    listing.status = 'sold';
    listing.soldTo = offer.buyer;
    listing.soldAt = new Date();
    listing.soldPrice = offer.amount;
    await listing.save({ session });

    // Reject all other pending offers for this listing
    await Offer.updateMany(
      { 
        listing: offer.listing, 
        _id: { $ne: offerId }, 
        status: 'pending' 
      },
      { 
        $set: { 
          status: 'rejected',
          responseMessage: 'Offer was accepted by another buyer',
          respondedBy: userId,
          respondedAt: new Date()
        }
      }
    ).session(session);

    await session.commitTransaction();
    session.endSession();

    res.status(200).json({
      success: true,
      message: 'Counter offer accepted successfully'
    });

  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    console.error('Error accepting counter offer:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Cancel an offer
exports.cancelOffer = async (req, res) => {
  try {
    const { offerId } = req.params;
    const userId = req.user.id;

    const offer = await Offer.findById(offerId);
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offer not found'
      });
    }

    // Verify user is the buyer
    if (offer.buyer.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to cancel this offer'
      });
    }

    if (offer.status !== 'pending' && offer.status !== 'countered') {
      return res.status(400).json({
        success: false,
        message: 'This offer cannot be cancelled'
      });
    }

    // Update offer status
    offer.status = 'cancelled';
    await offer.save();

    res.status(200).json({
      success: true,
      message: 'Offer cancelled successfully'
    });

  } catch (error) {
    console.error('Error cancelling offer:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};
