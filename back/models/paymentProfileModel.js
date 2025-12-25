// models/paymentProfileModel.js
const mongoose = require('mongoose');

const paymentProfileSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  // Stripe Connected Account ID for receiving payments
  stripeAccountId: {
    type: String,
    required: true,
    unique: true
  },
  // Account status
  accountStatus: {
    type: String,
    enum: ['pending', 'active', 'restricted', 'disabled'],
    default: 'pending'
  },
  // Account details
  accountDetails: {
    country: { type: String, required: true },
    currency: { type: String, required: true, default: 'usd' },
    accountHolderName: { type: String, required: true },
    accountHolderType: { 
      type: String, 
      enum: ['individual', 'company'],
      default: 'individual'
    },
  },
  // Bank account or card details (stored in Stripe, we just keep references)
  payoutMethods: [{
    type: {
      type: String,
      enum: ['bank_account', 'card', 'debit_card'],
      required: true
    },
    last4: String,
    bankName: String,
    isDefault: { type: Boolean, default: false },
    stripeBankAccountId: String, // Reference to Stripe bank account
    addedAt: { type: Date, default: Date.now }
  }],
  // Payment statistics
  statistics: {
    totalEarnings: { type: Number, default: 0 },
    totalPayouts: { type: Number, default: 0 },
    pendingBalance: { type: Number, default: 0 },
    lastPayoutDate: Date,
    transactionCount: { type: Number, default: 0 }
  },
  // Verification status
  verification: {
    isVerified: { type: Boolean, default: false },
    documentsSubmitted: { type: Boolean, default: false },
    verifiedAt: Date,
    requiresAdditionalInfo: { type: Boolean, default: false }
  },
  // Settings
  settings: {
    autoPayoutEnabled: { type: Boolean, default: true },
    minimumPayoutAmount: { type: Number, default: 1000 }, // In cents
    payoutSchedule: {
      type: String,
      enum: ['daily', 'weekly', 'monthly', 'manual'],
      default: 'weekly'
    }
  },
  // Metadata
  isActive: { type: Boolean, default: true },
  lastUpdated: { type: Date, default: Date.now }
}, { timestamps: true });

// Indexes
paymentProfileSchema.index({ 'verification.isVerified': 1 });

module.exports = mongoose.model('PaymentProfile', paymentProfileSchema);
