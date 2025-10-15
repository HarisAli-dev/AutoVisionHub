const Bid = require('../../models/marketplace/bidModel');
const Listing = require('../../models/marketplace/listingModel');
const User = require('../../models/users/userModel');
const mongoose = require('mongoose');

// Place a bid on a listing
exports.placeBid = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { listingId } = req.params;
    const { amount, maxBid, isAutoBid } = req.body;
    const userId = req.user.id;

    // Validate required fields
    if (!amount) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'Bid amount is required'
      });
    }

    // Get the listing
    const listing = await Listing.findById(listingId).session(session);
    if (!listing) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({
        success: false,
        message: 'Listing not found'
      });
    }

    // Check if listing is an auction
    if (!listing.isAuction) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'This listing is not an auction'
      });
    }

    // Check if auction is still active
    if (listing.status !== 'active' || !listing.isActive) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'Auction is no longer active'
      });
    }

    // Check if auction has ended
    if (listing.auctionEndTime && new Date() > listing.auctionEndTime) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'Auction has ended'
      });
    }

    // Check if user is not the seller
    if (listing.seller.toString() === userId) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'You cannot bid on your own listing'
      });
    }

    // Validate bid amount
    const minimumBid = listing.currentBid || listing.startingBid;
    if (amount <= minimumBid) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: `Bid must be higher than current bid of PKR ${minimumBid}`
      });
    }

    // Check bid increment
    if (listing.bidIncrement && (amount - minimumBid) < listing.bidIncrement) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: `Bid increment must be at least PKR ${listing.bidIncrement}`
      });
    }

    // Mark previous winning bid as outbid
    const previousWinningBid = await Bid.findOne({
      listing: listingId,
      isWinning: true
    }).session(session);

    if (previousWinningBid) {
      previousWinningBid.isWinning = false;
      previousWinningBid.isOutbid = true;
      previousWinningBid.status = 'outbid';
      previousWinningBid.outbidAt = new Date();
      await previousWinningBid.save({ session });
    }

    // Create new bid
    const newBid = new Bid({
      listing: listingId,
      bidder: userId,
      amount,
      maxBid: isAutoBid ? maxBid : undefined,
      isAutoBid: isAutoBid || false,
      isWinning: true,
      status: 'winning'
    });

    const savedBid = await newBid.save({ session });

    // Update listing with new current bid
    listing.currentBid = amount;
    await listing.save({ session });

    await session.commitTransaction();
    session.endSession();

    // Populate bidder information
    const populatedBid = await Bid.findById(savedBid._id)
      .populate('bidder', 'name profileImageUrl');

    res.status(201).json({
      success: true,
      message: 'Bid placed successfully',
      data: populatedBid
    });

  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    console.error('Error placing bid:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get bids for a listing
exports.getListingBids = async (req, res) => {
  try {
    const { listingId } = req.params;
    const { page = 1, limit = 20 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const bids = await Bid.find({ listing: listingId })
      .populate('bidder', 'name profileImageUrl')
      .sort({ amount: -1, bidTime: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Bid.countDocuments({ listing: listingId });

    res.status(200).json({
      success: true,
      data: {
        bids,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
          totalItems: total,
          itemsPerPage: parseInt(limit)
        }
      }
    });

  } catch (error) {
    console.error('Error fetching listing bids:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get user's bids
exports.getUserBids = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20, status } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const query = { bidder: userId };

    if (status) {
      query.status = status;
    }

    const bids = await Bid.find(query)
      .populate({
        path: 'listing',
        populate: {
          path: 'seller',
          select: 'name profileImageUrl'
        }
      })
      .sort({ bidTime: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Bid.countDocuments(query);

    res.status(200).json({
      success: true,
      data: {
        bids,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
          totalItems: total,
          itemsPerPage: parseInt(limit)
        }
      }
    });

  } catch (error) {
    console.error('Error fetching user bids:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Cancel a bid
exports.cancelBid = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { bidId } = req.params;
    const userId = req.user.id;

    const bid = await Bid.findById(bidId).session(session);
    if (!bid) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({
        success: false,
        message: 'Bid not found'
      });
    }

    if (bid.bidder.toString() !== userId) {
      await session.abortTransaction();
      session.endSession();
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to cancel this bid'
      });
    }

    if (bid.status !== 'active' && bid.status !== 'winning') {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel this bid'
      });
    }

    // Update bid status
    bid.status = 'cancelled';
    bid.isWinning = false;
    await bid.save({ session });

    // If this was the winning bid, find the next highest bid
    if (bid.isWinning) {
      const nextHighestBid = await Bid.findOne({
        listing: bid.listing,
        status: 'active',
        _id: { $ne: bidId }
      }).sort({ amount: -1 }).session(session);

      if (nextHighestBid) {
        nextHighestBid.isWinning = true;
        nextHighestBid.status = 'winning';
        await nextHighestBid.save({ session });

        // Update listing current bid
        const listing = await Listing.findById(bid.listing).session(session);
        listing.currentBid = nextHighestBid.amount;
        await listing.save({ session });
      } else {
        // No other bids, reset to starting bid
        const listing = await Listing.findById(bid.listing).session(session);
        listing.currentBid = listing.startingBid;
        await listing.save({ session });
      }
    }

    await session.commitTransaction();
    session.endSession();

    res.status(200).json({
      success: true,
      message: 'Bid cancelled successfully'
    });

  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    console.error('Error cancelling bid:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get auction statistics
exports.getAuctionStats = async (req, res) => {
  try {
    const { listingId } = req.params;

    const totalBids = await Bid.countDocuments({ listing: listingId });
    const uniqueBidders = await Bid.distinct('bidder', { listing: listingId });
    const highestBid = await Bid.findOne({ listing: listingId })
      .sort({ amount: -1 })
      .populate('bidder', 'name profileImageUrl');

    res.status(200).json({
      success: true,
      data: {
        totalBids,
        uniqueBidders: uniqueBidders.length,
        highestBid
      }
    });

  } catch (error) {
    console.error('Error fetching auction stats:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};
