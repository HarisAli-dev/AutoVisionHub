// models/userModel.js
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  profileImageUrl: { type: String},
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  phoneNumber: { type: String, required: true, unique: true },
  city: { type: String, required: true },
  role: {
    type: String,
    enum: ['admin', 'event_manager', 'community_member'],
    default: 'community_member',  // Default role is Community Member
  },
  fcmToken: { type: String }, // Firebase Cloud Messaging token for push notifications
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
