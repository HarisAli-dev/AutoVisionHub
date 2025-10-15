const mongoose = require('mongoose');

const marketplaceChatSchema = new mongoose.Schema({
  listing: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Listing', 
    required: true 
  },
  participants: [{ 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  }],
  // Chat metadata
  lastMessage: {
    content: { type: String },
    sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    timestamp: { type: Date },
    messageType: { 
      type: String, 
      enum: ['text', 'image', 'offer', 'bid', 'system'], 
      default: 'text' 
    }
  },
  // Status
  isActive: { type: Boolean, default: true },
  // Unread counts for each participant
  unreadCounts: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    count: { type: Number, default: 0 }
  }],
  // Related offer/bid if any
  relatedOffer: { type: mongoose.Schema.Types.ObjectId, ref: 'Offer' },
  relatedBid: { type: mongoose.Schema.Types.ObjectId, ref: 'Bid' }
}, { timestamps: true });

// Indexes for better performance
marketplaceChatSchema.index({ listing: 1 });
marketplaceChatSchema.index({ participants: 1 });
marketplaceChatSchema.index({ isActive: 1 });
marketplaceChatSchema.index({ updatedAt: -1 });

module.exports = mongoose.model('MarketplaceChat', marketplaceChatSchema);
