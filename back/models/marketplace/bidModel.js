const mongoose = require('mongoose');

const bidSchema = new mongoose.Schema({
  listing: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Listing', 
    required: true 
  },
  bidder: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  amount: { type: Number, required: true },
  isWinning: { type: Boolean, default: false },
  isOutbid: { type: Boolean, default: false },
  // Auto-bid settings
  maxBid: { type: Number }, // Maximum amount user is willing to bid
  isAutoBid: { type: Boolean, default: false },
  // Status
  status: { 
    type: String, 
    enum: ['active', 'outbid', 'winning', 'won', 'lost', 'cancelled'], 
    default: 'active' 
  },
  // Timestamps
  bidTime: { type: Date, default: Date.now },
  outbidAt: { type: Date },
  wonAt: { type: Date }
}, { timestamps: true });

// Indexes for better performance
bidSchema.index({ listing: 1, amount: -1 });
bidSchema.index({ bidder: 1 });
bidSchema.index({ status: 1 });
bidSchema.index({ bidTime: -1 });

// Ensure only one winning bid per listing
bidSchema.index({ listing: 1, isWinning: 1 }, { unique: true, partialFilterExpression: { isWinning: true } });

module.exports = mongoose.model('Bid', bidSchema);
