const mongoose = require('mongoose');

const listingSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  price: { type: Number, required: true },
  originalPrice: { type: Number }, // For showing original price in offers
  category: { 
    type: String, 
    enum: ['vehicle', 'part', 'accessory'], 
    required: true 
  },
  subcategory: { type: String }, // e.g., 'sedan', 'suv', 'engine', 'brakes'
  brand: { type: String, required: true },
  year: { type: Number },
  condition: { 
    type: String, 
    enum: ['excellent', 'good', 'fair', 'poor'], 
    required: true 
  },
  mileage: { type: Number }, // For vehicles
  fuelType: { 
    type: String, 
    enum: ['petrol', 'diesel', 'hybrid', 'electric', 'cng'] 
  },
  transmission: { 
    type: String, 
    enum: ['manual', 'automatic', 'cvt'] 
  },
  color: { type: String },
  images: [{ type: String, required: true }], // Array of image URLs
  location: { 
    city: { type: String, required: true },
    address: { type: String }
  },
  seller: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  isActive: { type: Boolean, default: true },
  isFeatured: { type: Boolean, default: false },
  viewCount: { type: Number, default: 0 },
  favoriteCount: { type: Number, default: 0 },
  // Stock/Quantity fields
  quantity: { type: Number, default: 1, min: 0 }, // Available stock
  originalQuantity: { type: Number, default: 1, min: 1 }, // Original stock when created
  // Auction/Bidding fields
  isAuction: { type: Boolean, default: false },
  auctionEndTime: { type: Date },
  startingBid: { type: Number },
  currentBid: { type: Number },
  bidIncrement: { type: Number, default: 1000 },
  // Negotiation fields
  isNegotiable: { type: Boolean, default: true },
  minimumOffer: { type: Number },
  // Status
  status: { 
    type: String, 
    enum: ['active', 'sold', 'pending', 'expired'], 
    default: 'active' 
  },
  soldTo: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  soldAt: { type: Date },
  soldPrice: { type: Number }
}, { timestamps: true });

// Indexes for better search performance
listingSchema.index({ title: 'text', description: 'text', brand: 'text' });
listingSchema.index({ category: 1, subcategory: 1 });
listingSchema.index({ price: 1 });
listingSchema.index({ location: 1 });
listingSchema.index({ seller: 1 });
listingSchema.index({ isActive: 1, status: 1 });
listingSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Listing', listingSchema);
