const mongoose = require('mongoose');
const Review = require('../../models/marketplace/reviewModel');
const Listing = require('../../models/marketplace/listingModel');

// Add or update a review
exports.addOrUpdateReview = async (req, res) => {
  try {
    const { listingId } = req.params;
    const { rating, review } = req.body;
    const userId = req.user.id;

    // Validate rating
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5'
      });
    }

    // Check if listing exists
    const listing = await Listing.findById(listingId);
    if (!listing) {
      return res.status(404).json({
        success: false,
        message: 'Listing not found'
      });
    }

    // Check if user already reviewed this listing
    let userReview = await Review.findOne({ listing: listingId, userId: userId });

    if (userReview) {
      // Update existing review
      userReview.rating = rating;
      userReview.review = review || '';
      await userReview.save();
      
      await userReview.populate('userId', 'name email profileImageUrl');
      
      return res.status(200).json({
        success: true,
        message: 'Review updated successfully',
        data: userReview
      });
    } else {
      // Validate: double-check no review exists (prevents race conditions)
      const existingReview = await Review.findOne({ listing: listingId, userId: userId });
      if (existingReview) {
        return res.status(400).json({
          success: false,
          message: 'You have already reviewed this listing'
        });
      }

      // Create new review
      const newReview = new Review({
        listing: listingId,
        userId: userId,
        rating,
        review: review || ''
      });
      
      await newReview.save();
      await newReview.populate('userId', 'name email profileImageUrl');
      
      return res.status(201).json({
        success: true,
        message: 'Review added successfully',
        data: newReview
      });
    }
  } catch (error) {
    console.error('Error adding/updating review:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get reviews for a listing
exports.getListingReviews = async (req, res) => {
  try {
    const { listingId } = req.params;
    const { page = 1, limit = 20 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    // First, get all reviews with raw data
    const reviewsRaw = await Review.find({ listing: listingId })
      .lean()
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    // Manually populate user data for each review
    const reviews = await Promise.all(
      reviewsRaw.map(async (review) => {
        const User = mongoose.model('User');
        const user = await User.findById(review.userId)
          .select('name email profileImageUrl')
          .lean();
        
        return {
          _id: review._id,
          listing: review.listing,
          userId: review.userId,
          rating: review.rating,
          review: review.review,
          createdAt: review.createdAt,
          updatedAt: review.updatedAt,
          user: user || { name: 'Unknown User', email: '', profileImageUrl: '' }
        };
      })
    );

    const totalReviews = await Review.countDocuments({ listing: listingId });

    // Calculate average rating using simple find
    const allReviews = await Review.find({ listing: listingId }).select('rating').lean();
    const averageRating = allReviews.length > 0 
      ? allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length 
      : 0;

    res.status(200).json({
      success: true,
      data: {
        reviews,
        averageRating: averageRating,
        totalReviews: totalReviews,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalReviews / parseInt(limit)),
          totalItems: totalReviews,
          itemsPerPage: parseInt(limit)
        }
      }
    });
  } catch (error) {
    console.error('Error fetching reviews:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Delete a review (user can only delete their own)
exports.deleteReview = async (req, res) => {
  try {
    const { reviewId } = req.params;
    const userId = req.user.id;

    const review = await Review.findById(reviewId);

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found'
      });
    }

    // Check if user owns this review
    if (review.userId.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to delete this review'
      });
    }

    await Review.findByIdAndDelete(reviewId);

    res.status(200).json({
      success: true,
      message: 'Review deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting review:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};
