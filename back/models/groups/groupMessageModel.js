const mongoose = require('mongoose');

const groupMessageSchema = new mongoose.Schema({
  groupId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Group',
    required: true
  },
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  senderName: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: ['text', 'image', 'video', 'voice', 'file', 'call', 'poll'],
    required: true
  },
  content: {
    type: String,
    default: null
  },
  mediaUrl: {
    type: String,
    default: null
  },
  thumbnailUrl: {
    type: String,
    default: null
  },
  duration: {
    type: Number,
    default: null
  },
  callType: {
    type: String,
    enum: ['missed', 'outgoing', 'incoming', null],
    default: null
  },
  pollId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Poll',
    default: null
  },
  status: {
    type: String,
    enum: ['sent', 'delivered', 'seen'],
    default: 'sent'
  },
  isDeleted: {
    type: Boolean,
    default: false
  },
  deletedFor: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],

}, { timestamps: true });

module.exports = mongoose.model('GroupMessage', groupMessageSchema);