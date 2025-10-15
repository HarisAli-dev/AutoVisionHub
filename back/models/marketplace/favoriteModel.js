const mongoose = require('mongoose');

const favoriteSchema = new mongoose.Schema({
  user: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  listing: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Listing', 
    required: true 
  }
}, { timestamps: true });

// Ensure one favorite per user per listing
favoriteSchema.index({ user: 1, listing: 1 }, { unique: true });

// Indexes for better performance
favoriteSchema.index({ user: 1 });
favoriteSchema.index({ listing: 1 });
favoriteSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Favorite', favoriteSchema);
