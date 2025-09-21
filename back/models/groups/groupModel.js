const mongoose = require('mongoose');

const groupSchema = new mongoose.Schema({
  groupName: {
    type: String,
    default: 'New Group'
  },
  description: {
    type: String,
    default: null
  },
  groupImageUrl: {
    type: String,
    default: null
  },
  participants: {
    type: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }],
    required: true,
  },
  lastMessage: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'GroupMessage',
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
  },
  admins: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }]
}, { timestamps: true });

module.exports = mongoose.model('Group', groupSchema);