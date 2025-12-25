const Listing = require('../../models/marketplace/listingModel');
const Favorite = require('../../models/marketplace/favoriteModel');
const Bid = require('../../models/marketplace/bidModel');
const MarketplaceChat = require('../../models/marketplace/marketplaceChatModel');
const User = require('../../models/users/userModel');
const mongoose = require('mongoose');
const cloudinary = require('../../config/cloudinary');
const popularityService = require('../../services/popularityService');

// Helper function to extract publicId from Cloudinary URL
const extractPublicId = (url) => {
  try {
    // Cloudinary URLs typically look like:
    // https://res.cloudinary.com/cloud_name/image/upload/v1234567890/folder/filename.ext
    const parts = url.split('/');
    const uploadIndex = parts.indexOf('upload');
    if (uploadIndex !== -1 && uploadIndex + 2 < parts.length) {
      // Get everything after 'upload/v123456/' and remove file extension
      const pathParts = parts.slice(uploadIndex + 2);
      const fullPath = pathParts.join('/');
      // Remove file extension
      return fullPath.replace(/\.[^/.]+$/, '');
    }
    return null;
  } catch (error) {
    console.error('Error extracting publicId from URL:', url, error);
    return null;
  }
};

// Create a new listing
exports.createListing = async (req, res) => {
  try {
    const {
      title,
      description,
      price,
      originalPrice,
      category,
      subcategory,
      brand,
      year,
      condition,
      mileage,
      fuelType,
      transmission,
      color,
      images,
      location,
      isAuction,
      auctionEndTime,
      startingBid,
      bidIncrement,
      quantity
    } = req.body;

    const userId = req.user.id;

    // Validate required fields
    if (!title || !description || !price || !category || !brand || !condition || !images || !location) {
      return res.status(400).json({
        success: false,
        message: 'All required fields must be provided'
      });
    }

    // Validate auction fields if it's an auction
    if (isAuction && (!auctionEndTime || !startingBid)) {
      return res.status(400).json({
        success: false,
        message: 'Auction end time and starting bid are required for auction listings'
      });
    }

    const listingData = {
      title,
      description,
      price,
      originalPrice,
      category,
      subcategory,
      brand,
      year,
      condition,
      mileage,
      fuelType,
      transmission,
      color,
      images,
      location,
      seller: userId,
      quantity: quantity && quantity > 0 ? quantity : 1,
      originalQuantity: quantity && quantity > 0 ? quantity : 1,
      isAuction,
      auctionEndTime: isAuction ? new Date(auctionEndTime) : undefined,
      startingBid: isAuction ? startingBid : undefined,
      currentBid: isAuction ? startingBid : undefined,
      bidIncrement: isAuction ? (bidIncrement || 1000) : undefined
    };

    const newListing = new Listing(listingData);
    const savedListing = await newListing.save();

    // Populate seller information
    const populatedListing = await Listing.findById(savedListing._id)
      .populate('seller', 'name email phoneNumber city profileImageUrl');

    res.status(201).json({
      success: true,
      message: 'Listing created successfully',
      data: populatedListing
    });

  } catch (error) {
    console.error('Error creating listing:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get all listings with filters and pagination
exports.getAllListings = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      category,
      subcategory,
      brand,
      minPrice,
      maxPrice,
      condition,
      location,
      search,
      sortBy = 'createdAt',
      sortOrder = 'desc',
      isAuction
    } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const query = { isActive: true, status: 'active' };

    // Apply filters
    if (category) query.category = category;
    if (subcategory) query.subcategory = subcategory;
    if (brand) query.brand = new RegExp(brand, 'i');
    if (minPrice || maxPrice) {
      query.price = {};
      if (minPrice) query.price.$gte = parseInt(minPrice);
      if (maxPrice) query.price.$lte = parseInt(maxPrice);
    }
    if (condition) query.condition = condition;
    if (location) query['location.city'] = new RegExp(location, 'i');
    if (isAuction !== undefined) query.isAuction = isAuction === 'true';

    // Text search
    if (search) {
      query.$text = { $search: search };
    }

    // Handle popularity-based sorting separately as it requires aggregation
    const isPopularitySort = sortBy === 'popularity';
    
    let listings;
    let total = await Listing.countDocuments(query);
    
    if (isPopularitySort) {
      // For popularity sorting, fetch all matching listings first
      const allListings = await Listing.find(query)
        .populate('seller', 'name email phoneNumber city profileImageUrl');
      
      // Enhance with popularity metrics and sort
      const sortedListings = await popularityService.filterAndSortByPopularity(
        allListings,
        {
          clickWeight: parseFloat(req.query.clickWeight) || 1.0,
          visitorWeight: parseFloat(req.query.visitorWeight) || 2.0,
          sortOrder: sortOrder || 'desc'
        }
      );
      
      // Apply pagination after sorting
      listings = sortedListings.slice(skip, skip + parseInt(limit));
    } else {
      // Standard sorting
      const sortOptions = {};
      if (sortBy === 'price') {
        sortOptions.price = sortOrder === 'asc' ? 1 : -1;
      } else if (sortBy === 'createdAt') {
        sortOptions.createdAt = sortOrder === 'asc' ? 1 : -1;
      } else if (sortBy === 'viewCount') {
        sortOptions.viewCount = sortOrder === 'asc' ? 1 : -1;
      } else if (sortBy === 'clickCount') {
        sortOptions.clickCount = sortOrder === 'asc' ? 1 : -1;
      }

      listings = await Listing.find(query)
        .populate('seller', 'name email phoneNumber city profileImageUrl')
        .sort(sortOptions)
        .skip(skip)
        .limit(parseInt(limit));
    }

    res.status(200).json({
      success: true,
      data: {
        listings,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
          totalItems: total,
          itemsPerPage: parseInt(limit)
        }
      }
    });

  } catch (error) {
    console.error('Error fetching listings:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get single listing by ID
exports.getListingById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id; // User may or may not be authenticated

    const listing = await Listing.findById(id)
      .populate('seller', 'name email phoneNumber city profileImageUrl');

    if (!listing) {
      return res.status(404).json({
        success: false,
        message: 'Listing not found'
      });
    }

    // Increment view count
    listing.viewCount += 1;
    
    // Increment click count when item is clicked
    listing.clickCount += 1;
    await listing.save();

    // If user is authenticated, add item to visitedItems and recentlyViewed
    if (userId) {
      const user = await User.findById(userId);
      
      // Add to visitedItems (prevents duplicates)
      await User.findByIdAndUpdate(
        userId,
        { $addToSet: { visitedItems: id } },
        { new: true }
      );

      // Add to recentlyViewed with timestamp
      // Remove existing entry if present, then add to beginning
      await User.findByIdAndUpdate(
        userId,
        { $pull: { recentlyViewed: { listing: id } } }
      );
      
      await User.findByIdAndUpdate(
        userId,
        { 
          $push: { 
            recentlyViewed: { 
              $each: [{ listing: id, viewedAt: new Date() }],
              $position: 0,
              $slice: 20 // Keep only last 20 viewed items
            }
          }
        },
        { new: true }
      );
    }

    // Get current highest bid if it's an auction
    let currentBid = null;
    if (listing.isAuction) {
      currentBid = await Bid.findOne({ listing: id, isWinning: true })
        .populate('bidder', 'name profileImageUrl')
        .sort({ amount: -1 });
    }

    res.status(200).json({
      success: true,
      data: {
        listing,
        currentBid
      }
    });

  } catch (error) {
    console.error('Error fetching listing:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get user's own listings
exports.getMyListings = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20, status } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const query = { seller: userId };

    if (status) {
      query.status = status;
    }

    const listings = await Listing.find(query)
      .populate('seller', 'name email phoneNumber city profileImageUrl')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Listing.countDocuments(query);

    res.status(200).json({
      success: true,
      data: {
        listings,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
          totalItems: total,
          itemsPerPage: parseInt(limit)
        }
      }
    });

  } catch (error) {
    console.error('Error fetching user listings:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Update listing
exports.updateListing = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const updateData = req.body;

    const listing = await Listing.findById(id);

    if (!listing) {
      return res.status(404).json({
        success: false,
        message: 'Listing not found'
      });
    }

    if (listing.seller.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to update this listing'
      });
    }

    // Don't allow updating certain fields if listing has bids
    if (listing.isAuction) {
      const hasBids = await Bid.exists({ listing: id });
      if (hasBids && (updateData.price || updateData.startingBid)) {
        return res.status(400).json({
          success: false,
          message: 'Cannot update price or starting bid after bids have been placed'
        });
      }
    }

    const updatedListing = await Listing.findByIdAndUpdate(
      id,
      updateData,
      { new: true }
    ).populate('seller', 'name email phoneNumber city profileImageUrl');

    res.status(200).json({
      success: true,
      message: 'Listing updated successfully',
      data: updatedListing
    });

  } catch (error) {
    console.error('Error updating listing:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Delete listing
exports.deleteListing = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const listing = await Listing.findById(id);

    if (!listing) {
      return res.status(404).json({
        success: false,
        message: 'Listing not found'
      });
    }

    if (listing.seller.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to delete this listing'
      });
    }

    // Delete images from Cloudinary
    if (listing.images && listing.images.length > 0) {
      console.log('Deleting images from Cloudinary:', listing.images);
      
      const deletePromises = listing.images.map(async (imageUrl) => {
        try {
          const publicId = extractPublicId(imageUrl);
          if (publicId) {
            console.log('Deleting image with publicId:', publicId);
            const result = await cloudinary.uploader.destroy(publicId);
            console.log('Cloudinary delete result:', result);
            return result;
          }
        } catch (error) {
          console.error('Error deleting image:', imageUrl, error);
          return { result: 'error', publicId: publicId };
        }
      });

      try {
        await Promise.all(deletePromises);
        console.log('All images deleted from Cloudinary');
      } catch (error) {
        console.error('Error deleting some images from Cloudinary:', error);
        // Continue with listing deletion even if image deletion fails
      }
    }

    // Hard delete the listing and related data
    await Promise.all([
      // Delete the listing
      Listing.findByIdAndDelete(id),
      // Delete related favorites
      Favorite.deleteMany({ listing: id }),
      // Delete related bids
      Bid.deleteMany({ listing: id }),
      // Delete related marketplace chats
      MarketplaceChat.deleteMany({ listing: id })
    ]);

    res.status(200).json({
      success: true,
      message: 'Listing and associated data deleted successfully'
    });

  } catch (error) {
    console.error('Error deleting listing:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Toggle favorite listing
exports.toggleFavorite = async (req, res) => {
  try {
    const { listingId } = req.params;
    const userId = req.user.id;

    const existingFavorite = await Favorite.findOne({
      user: userId,
      listing: listingId
    });

    if (existingFavorite) {
      // Remove from favorites
      await Favorite.findByIdAndDelete(existingFavorite._id);
      
      // Decrement favorite count
      await Listing.findByIdAndUpdate(listingId, {
        $inc: { favoriteCount: -1 }
      });

      res.status(200).json({
        success: true,
        message: 'Removed from favorites',
        isFavorited: false
      });
    } else {
      // Add to favorites
      const newFavorite = new Favorite({
        user: userId,
        listing: listingId
      });
      await newFavorite.save();

      // Increment favorite count
      await Listing.findByIdAndUpdate(listingId, {
        $inc: { favoriteCount: 1 }
      });

      res.status(200).json({
        success: true,
        message: 'Added to favorites',
        isFavorited: true
      });
    }

  } catch (error) {
    console.error('Error toggling favorite:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get user's favorite listings
exports.getFavoriteListings = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const favorites = await Favorite.find({ user: userId })
      .populate({
        path: 'listing',
        populate: {
          path: 'seller',
          select: 'name email phoneNumber city profileImageUrl'
        }
      })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Favorite.countDocuments({ user: userId });

    res.status(200).json({
      success: true,
      data: {
        favorites: favorites.map(fav => fav.listing),
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
          totalItems: total,
          itemsPerPage: parseInt(limit)
        }
      }
    });

  } catch (error) {
    console.error('Error fetching favorite listings:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get user's recently viewed items
exports.getRecentlyViewedItems = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Get user with visitedItems
    const user = await User.findById(userId).select('visitedItems');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Get visited item IDs (reverse to show most recent first)
    const visitedItemIds = (user.visitedItems || []).reverse();
    const total = visitedItemIds.length;

    // Apply pagination
    const paginatedIds = visitedItemIds.slice(skip, skip + parseInt(limit));

    if (paginatedIds.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          listings: [],
          pagination: {
            currentPage: parseInt(page),
            totalPages: Math.ceil(total / parseInt(limit)),
            totalItems: total,
            itemsPerPage: parseInt(limit)
          }
        }
      });
    }

    // Fetch listings with populated seller
    const listings = await Listing.find({
      _id: { $in: paginatedIds },
      isActive: true,
      status: 'active'
    })
      .populate('seller', 'name email phoneNumber city profileImageUrl')
      .sort({ updatedAt: -1 }); // Sort by most recently updated

    // Maintain order based on visitedItems array (most recent first)
    const orderedListings = paginatedIds
      .map(id => listings.find(listing => listing._id.toString() === id.toString()))
      .filter(Boolean); // Remove undefined/null items

    res.status(200).json({
      success: true,
      data: {
        listings: orderedListings,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
          totalItems: total,
          itemsPerPage: parseInt(limit)
        }
      }
    });

  } catch (error) {
    console.error('Error fetching recently viewed items:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get user's recently viewed listings with timestamps
exports.getRecentlyViewedListings = async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit = 10 } = req.query;

    const user = await User.findById(userId)
      .populate({
        path: 'recentlyViewed.listing',
        match: { isActive: true },
        populate: {
          path: 'seller',
          select: 'name email phoneNumber city profileImageUrl'
        }
      });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Filter out null listings (deleted or inactive) and apply limit
    const recentlyViewed = user.recentlyViewed
      .filter(item => item.listing)
      .slice(0, parseInt(limit))
      .map(item => ({
        listing: item.listing,
        viewedAt: item.viewedAt
      }));

    res.status(200).json({
      success: true,
      data: {
        recentlyViewed,
        count: recentlyViewed.length
      }
    });

  } catch (error) {
    console.error('Error fetching recently viewed listings:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

