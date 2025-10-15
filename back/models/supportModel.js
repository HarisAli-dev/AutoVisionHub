const mongoose = require('mongoose');

// Support Conversation Schema
const supportConversationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  userMessage: {
    type: String,
    required: true,
    trim: true
  },
  aiResponse: {
    type: String,
    required: true
  },
  context: {
    type: String,
    enum: ['customer_support', 'general', 'technical', 'billing', 'events', 'livestream'],
    default: 'general'
  },
  timestamp: {
    type: Date,
    default: Date.now
  },
  feedback: {
    rating: {
      type: Number,
      min: 1,
      max: 5
    },
    comment: String,
    submittedAt: Date
  },
  escalated: {
    type: Boolean,
    default: false
  },
  escalatedAt: Date,
  ticketId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'SupportTicket'
  }
}, {
  timestamps: true
});

// Support Ticket Schema
const supportTicketSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  subject: {
    type: String,
    required: true,
    trim: true
  },
  message: {
    type: String,
    required: true
  },
  category: {
    type: String,
    enum: ['general', 'technical', 'billing', 'account', 'events', 'livestream', 'groups'],
    default: 'general'
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'urgent'],
    default: 'medium'
  },
  status: {
    type: String,
    enum: ['open', 'in_progress', 'waiting_for_user', 'resolved', 'closed'],
    default: 'open'
  },
  assignedTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User' // Support agent
  },
  source: {
    type: String,
    enum: ['chatbot_escalation', 'direct_contact', 'email', 'phone'],
    default: 'direct_contact'
  },
  responses: [{
    message: String,
    sentBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    sentAt: {
      type: Date,
      default: Date.now
    },
    isFromSupport: {
      type: Boolean,
      default: false
    }
  }],
  tags: [String],
  attachments: [{
    filename: String,
    url: String,
    uploadedAt: {
      type: Date,
      default: Date.now
    }
  }],
  resolvedAt: Date,
  closedAt: Date,
  resolutionNotes: String
}, {
  timestamps: true
});

// Support Analytics Schema
const supportAnalyticsSchema = new mongoose.Schema({
  date: {
    type: Date,
    required: true
  },
  totalConversations: {
    type: Number,
    default: 0
  },
  totalTickets: {
    type: Number,
    default: 0
  },
  averageResponseTime: Number, // in minutes
  satisfactionRating: Number, // average rating
  commonIssues: [{
    category: String,
    count: Number
  }],
  escalationRate: Number, // percentage of conversations escalated
  resolutionRate: Number // percentage of tickets resolved
}, {
  timestamps: true
});

// Indexes for better query performance
supportConversationSchema.index({ userId: 1, timestamp: -1 });
supportConversationSchema.index({ context: 1 });
supportConversationSchema.index({ timestamp: -1 });

supportTicketSchema.index({ userId: 1, status: 1 });
supportTicketSchema.index({ assignedTo: 1, status: 1 });
supportTicketSchema.index({ createdAt: -1 });
supportTicketSchema.index({ category: 1, priority: 1 });

supportAnalyticsSchema.index({ date: -1 });

// Create models
const SupportConversation = mongoose.model('SupportConversation', supportConversationSchema);
const SupportTicket = mongoose.model('SupportTicket', supportTicketSchema);
const SupportAnalytics = mongoose.model('SupportAnalytics', supportAnalyticsSchema);

module.exports = {
  SupportConversation,
  SupportTicket,
  SupportAnalytics
};