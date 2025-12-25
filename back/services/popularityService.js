const User = require('../models/users/userModel');
const Listing = require('../models/marketplace/listingModel');
const mongoose = require('mongoose');

/**
 * Calculate popularity score for a listing based on clickCount and visitedItems count
 * The algorithm considers:
 * 1. Click count (direct clicks on the item)
 * 2. Unique visitor count (number of users who visited the item)
 * 
 * Formula: popularityScore = (clickCount * clickWeight) + (uniqueVisitors * visitorWeight)
 * 
 * @param {Object} listing - The listing document
 * @param {Object} options - Configuration options
 * @param {Number} options.clickWeight - Weight for click count (default: 1.0)
 * @param {Number} options.visitorWeight - Weight for unique visitors (default: 2.0)
 * @returns {Number} Popularity score
 */
const calculatePopularityScore = (listing, options = {}) => {
  const { clickWeight = 1.0, visitorWeight = 2.0 } = options;
  
  const clickCount = listing.clickCount || 0;
  const uniqueVisitors = listing.uniqueVisitors || 0;
  
  // Calculate popularity score
  const popularityScore = (clickCount * clickWeight) + (uniqueVisitors * visitorWeight);
  
  return popularityScore;
};

/**
 * Calculate unique visitors count for listings
 * This aggregates visitedItems from all users to count unique visitors per listing
 * 
 * @param {Array} listingIds - Array of listing IDs (optional, if not provided, calculates for all)
 * @returns {Promise<Map>} Map of listingId -> unique visitor count
 */
const calculateUniqueVisitors = async (listingIds = null) => {
  try {
    const matchQuery = listingIds 
      ? { visitedItems: { $in: listingIds.map(id => new mongoose.Types.ObjectId(id)) } }
      : { visitedItems: { $exists: true, $ne: [] } };
    
    // Aggregate to count unique visitors per listing
    const visitorsByListing = await User.aggregate([
      { $match: matchQuery },
      { $unwind: '$visitedItems' },
      {
        $group: {
          _id: '$visitedItems',
          uniqueVisitors: { $sum: 1 }
        }
      }
    ]);
    
    // Convert to Map for easy lookup
    const visitorsMap = new Map();
    visitorsByListing.forEach(item => {
      visitorsMap.set(item._id.toString(), item.uniqueVisitors);
    });
    
    return visitorsMap;
  } catch (error) {
    console.error('Error calculating unique visitors:', error);
    return new Map();
  }
};

/**
 * Enhance listings with popularity metrics
 * Adds uniqueVisitors count and popularityScore to each listing
 * 
 * @param {Array} listings - Array of listing documents
 * @param {Object} options - Options for popularity calculation
 * @returns {Promise<Array>} Listings with popularity metrics
 */
const enhanceListingsWithPopularity = async (listings, options = {}) => {
  try {
    if (!listings || listings.length === 0) {
      return listings;
    }
    
    // Extract listing IDs - handle both _id and id properties
    const listingIds = listings.map(listing => {
      const id = listing._id || listing.id;
      return id ? id.toString() : null;
    }).filter(id => id !== null);
    
    const visitorsMap = await calculateUniqueVisitors(listingIds);
    
    // Enhance each listing with popularity metrics
    const enhancedListings = listings.map(listing => {
      const id = listing._id || listing.id;
      const listingId = id ? id.toString() : null;
      const uniqueVisitors = listingId ? (visitorsMap.get(listingId) || 0) : 0;
      
      // Convert to plain object if it's a Mongoose document
      const listingObj = listing.toObject ? listing.toObject() : listing;
      
      // Add popularity metrics
      listingObj.uniqueVisitors = uniqueVisitors;
      listingObj.popularityScore = calculatePopularityScore(
        { ...listingObj, uniqueVisitors },
        options
      );
      
      return listingObj;
    });
    
    return enhancedListings;
  } catch (error) {
    console.error('Error enhancing listings with popularity:', error);
    return listings;
  }
};

/**
 * Sort listings by popularity score
 * 
 * @param {Array} listings - Array of listing documents (with popularity metrics)
 * @param {String} order - 'desc' (default) or 'asc'
 * @returns {Array} Sorted listings
 */
const sortByPopularity = (listings, order = 'desc') => {
  return [...listings].sort((a, b) => {
    const scoreA = a.popularityScore || 0;
    const scoreB = b.popularityScore || 0;
    
    return order === 'asc' ? scoreA - scoreB : scoreB - scoreA;
  });
};

/**
 * Filter and sort listings by popularity
 * This is the main function that combines filtering and popularity-based sorting
 * 
 * @param {Array} listings - Array of listing documents
 * @param {Object} options - Options for filtering and sorting
 * @param {Number} options.clickWeight - Weight for click count (default: 1.0)
 * @param {Number} options.visitorWeight - Weight for unique visitors (default: 2.0)
 * @param {String} options.sortOrder - 'desc' (default) or 'asc'
 * @param {Number} options.minPopularityScore - Minimum popularity score to include (optional)
 * @returns {Promise<Array>} Filtered and sorted listings by popularity
 */
const filterAndSortByPopularity = async (listings, options = {}) => {
  try {
    const {
      clickWeight = 1.0,
      visitorWeight = 2.0,
      sortOrder = 'desc',
      minPopularityScore = null
    } = options;
    
    // Enhance listings with popularity metrics
    let enhancedListings = await enhanceListingsWithPopularity(listings, {
      clickWeight,
      visitorWeight
    });
    
    // Filter by minimum popularity score if specified
    if (minPopularityScore !== null) {
      enhancedListings = enhancedListings.filter(
        listing => listing.popularityScore >= minPopularityScore
      );
    }
    
    // Sort by popularity
    const sortedListings = sortByPopularity(enhancedListings, sortOrder);
    
    return sortedListings;
  } catch (error) {
    console.error('Error filtering and sorting by popularity:', error);
    return listings;
  }
};

module.exports = {
  calculatePopularityScore,
  calculateUniqueVisitors,
  enhanceListingsWithPopularity,
  sortByPopularity,
  filterAndSortByPopularity
};

