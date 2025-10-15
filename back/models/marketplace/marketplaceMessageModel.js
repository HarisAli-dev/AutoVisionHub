const mongoose = require('mongoose');

const marketplaceMessageSchema = new mongoose.Schema({
  chat: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'MarketplaceChat', 
    required: true 
  },
  sender: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  content: { type: String, required: true },
  messageType: { 
    type: String, 
    enum: ['text', 'image', 'offer', 'bid', 'system'], 
    default: 'text' 
  },
  // For image messages
  imageUrl: { type: String },
  // For offer messages
  offerData: {
    amount: { type: Number },
    offerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Offer' }
  },
  // For bid messages
  bidData: {
    amount: { type: Number },
    bidId: { type: mongoose.Schema.Types.ObjectId, ref: 'Bid' }
  },
  // Read status
  readBy: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    readAt: { type: Date, default: Date.now }
  }],
  // Reply to another message
  replyTo: { type: mongoose.Schema.Types.ObjectId, ref: 'MarketplaceMessage' },
  // Status
  isDeleted: { type: Boolean, default: false },
  deletedAt: { type: Date },
  deletedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

// Indexes for better performance
marketplaceMessageSchema.index({ chat: 1, createdAt: -1 });
marketplaceMessageSchema.index({ sender: 1 });
marketplaceMessageSchema.index({ messageType: 1 });
marketplaceMessageSchema.index({ isDeleted: 1 });

module.exports = mongoose.model('MarketplaceMessage', marketplaceMessageSchema);
