const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema({
  reportType: {
    type: String,
    enum: ['user', 'listitem', 'reactivation_request', 'unban_request'],
    required: true
  },
  reportedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: function() {
      return this.reportType !== 'unban_request';
    }
  },
  reportedUser: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  reportedListItem: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Listing',
    default: null
  },
  reason: {
    type: String,
    required: true,
    trim: true
  },
  proofImages: [{
    type: String, // URLs to images stored in Cloudinary
    default: []
  }],
  status: {
    type: String,
    enum: ['pending', 'reviewed', 'resolved', 'ignored', 'approved', 'rejected'],
    default: 'pending'
  },
  adminNotes: {
    type: String,
    default: null
  },
  reviewedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  reviewedAt: {
    type: Date,
    default: null
  },
  actionTaken: {
    type: String,
    enum: ['none', 'user_banned', 'user_deleted', 'user_unbanned', 'listitem_removed', 'listitem_reactivated', 'ignored'],
    default: 'none'
  }
}, { timestamps: true });

// Index for faster queries
reportSchema.index({ reportType: 1, status: 1 });
reportSchema.index({ reportedUser: 1 });
reportSchema.index({ reportedListItem: 1 });
reportSchema.index({ reportedBy: 1 });

module.exports = mongoose.model('Report', reportSchema);
