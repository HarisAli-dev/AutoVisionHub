const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema({
  participants: {
    type: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }],
    required: true, // It's good practice to make this required
    validate: {
      validator: function(v) {
        return v.length === 2;
      },
      message: 'Chat must have exactly 2 participants.'
    }
  },
  lastMessage: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'ChatMessage',
    default: null
  },
  unreadCounts: {
    type: Map,
    of: Number,
    default: {}
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, { timestamps: true });

// Virtual field and toJSON serialization
chatSchema.virtual('id').get(function() {
  return this._id.toHexString();
});

chatSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id;
    delete ret.__v;
    delete ret._id; // Better to remove _id to prevent confusion
    return ret;
  }
});

module.exports = mongoose.model('Chat', chatSchema);