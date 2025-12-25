// models/transactionModel.js
const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  // Transaction parties
  fromUserId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  toUserId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  // Transaction type and details
  transactionType: {
    type: String,
    enum: ['event_booking', 'marketplace_purchase', 'marketplace_bid', 'other'],
    required: true
  },
  relatedEntityId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true
  },
  relatedEntityType: {
    type: String,
    enum: ['Event', 'Listing', 'Other'],
    required: true
  },
  // Amount details
  amount: {
    type: Number,
    required: true,
    min: 0
  },
  currency: {
    type: String,
    default: 'usd'
  },
  // Platform fee (your cut)
  platformFee: {
    type: Number,
    required: true,
    default: 0
  },
  platformFeePercentage: {
    type: Number,
    default: 0 // e.g., 5 for 5%
  },
  // Net amount to recipient
  netAmount: {
    type: Number,
    required: true
  },
  // Stripe references
  stripePaymentIntentId: String,
  stripeChargeId: String,
  stripeTransferId: String, // Transfer to connected account
  // Transaction status
  status: {
    type: String,
    enum: ['pending', 'processing', 'completed', 'failed', 'refunded', 'cancelled'],
    default: 'pending'
  },
  // Payment and payout status
  paymentStatus: {
    type: String,
    enum: ['pending', 'captured', 'failed'],
    default: 'pending'
  },
  payoutStatus: {
    type: String,
    enum: ['pending', 'in_transit', 'paid', 'failed'],
    default: 'pending'
  },
  // Timing
  paymentDate: Date,
  payoutDate: Date,
  completedAt: Date,
  // Error handling
  errorMessage: String,
  failureReason: String,
  // Refund information
  refundAmount: Number,
  refundDate: Date,
  refundReason: String,
  // Description
  description: String,
  metadata: mongoose.Schema.Types.Mixed
}, { timestamps: true });

// Indexes for efficient queries
transactionSchema.index({ fromUserId: 1, createdAt: -1 });
transactionSchema.index({ toUserId: 1, createdAt: -1 });
transactionSchema.index({ status: 1 });
transactionSchema.index({ transactionType: 1 });
transactionSchema.index({ stripePaymentIntentId: 1 });

module.exports = mongoose.model('Transaction', transactionSchema);
