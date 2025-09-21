const mongoose = require('mongoose');

const chatMessageSchema = new mongoose.Schema({
  chatId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Chat',
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
    enum: ['text', 'image', 'video', 'voice', 'file', 'call'],
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
  }]
}, { timestamps: true });

// Virtual field to match frontend naming (_id -> id)
chatMessageSchema.virtual('id').get(function() {
  return this._id.toHexString();
});

// Ensure virtual fields are serialized when converted to JSON
chatMessageSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id;
    delete ret.__v;
    return ret;
  }
});

const ChatMessage = mongoose.model('ChatMessage', chatMessageSchema);

module.exports = ChatMessage;
