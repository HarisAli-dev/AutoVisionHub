const mongoose = require('mongoose');

const offerSchema = new mongoose.Schema({
  listing: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Listing', 
    required: true 
  },
  buyer: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  seller: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  amount: { type: Number, required: true },
  message: { type: String }, // Optional message with the offer
  // Status
  status: { 
    type: String, 
    enum: ['pending', 'accepted', 'rejected', 'countered', 'expired', 'cancelled'], 
    default: 'pending' 
  },
  // Counter offer details
  counterOffer: {
    amount: { type: Number },
    message: { type: String },
    counterOfferBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    counterOfferAt: { type: Date }
  },
  // Response details
  responseMessage: { type: String },
  respondedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  respondedAt: { type: Date },
  // Expiration
  expiresAt: { type: Date, default: () => new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) }, // 7 days
  // Timestamps
  offerTime: { type: Date, default: Date.now }
}, { timestamps: true });

// Indexes for better performance
offerSchema.index({ listing: 1, status: 1 });
offerSchema.index({ buyer: 1 });
offerSchema.index({ seller: 1 });
offerSchema.index({ status: 1 });
offerSchema.index({ offerTime: -1 });
offerSchema.index({ expiresAt: 1 });

module.exports = mongoose.model('Offer', offerSchema);
