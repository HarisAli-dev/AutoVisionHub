// pollModel.js
const mongoose = require('mongoose');

const pollSchema = new mongoose.Schema(
  {
    question: { type: String, required: true }, // Poll question
    options: [{ type: String, required: true }], // Poll options
    votes: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    option: String
  }], // List of users who voted
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // User who created the poll
    groupId: { type: mongoose.Schema.Types.ObjectId, ref: 'Group' }, // Group ID if the poll is for a group
  },
  { timestamps: true }
);

module.exports = mongoose.model('Poll', pollSchema);