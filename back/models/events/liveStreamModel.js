const mongoose = require('mongoose');

const liveStreamSchema = new mongoose.Schema({
  eventId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Event',
    required: true
  },
  roomId: {
    type: String,
    required: true,
    unique: true
  },
  hostId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  streamTitle: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200
  },
  streamDescription: {
    type: String,
    trim: true,
    maxlength: 1000
  },
  isActive: {
    type: Boolean,
    default: true
  },
  startTime: {
    type: Date,
    default: Date.now,
    required: true
  },
  endTime: {
    type: Date
  },
  duration: {
    type: Number, // in seconds
    default: 0
  },
  viewers: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    joinTime: {
      type: Date,
      default: Date.now
    },
    leaveTime: {
      type: Date
    },
    totalViewTime: {
      type: Number, // in seconds
      default: 0
    }
  }],
  analytics: {
    totalViewers: {
      type: Number,
      default: 0
    },
    maxConcurrentViewers: {
      type: Number,
      default: 0
    },
    totalViewTime: {
      type: Number, // total seconds watched by all viewers
      default: 0
    },
    engagementEvents: [{
      userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      eventType: {
        type: String,
        enum: ['like', 'comment', 'share', 'reaction', 'question', 'poll_vote', 'chat_message'],
        required: true
      },
      data: mongoose.Schema.Types.Mixed,
      timestamp: {
        type: Date,
        default: Date.now
      }
    }],
    averageViewTime: {
      type: Number,
      default: 0
    },
    engagementRate: {
      type: Number,
      default: 0
    }
  },
  recordingUrl: {
    type: String, // URL to recorded video if available
    trim: true
  },
  // Chatbot integration with ZEGOCLOUD
  chatbot: {
    isActive: {
      type: Boolean,
      default: false
    },
    instanceId: {
      type: String,
      trim: true
    },
    agentId: {
      type: String,
      default: 'autovision-ai-assistant'
    },
    startTime: {
      type: Date
    },
    endTime: {
      type: Date
    },
    messagesCount: {
      type: Number,
      default: 0
    },
    config: {
      autoStart: {
        type: Boolean,
        default: true
      },
      welcomeMessage: String
    }
  },
  // Chatbot conversation data
  chatbotData: {
    isEnabled: {
      type: Boolean,
      default: false
    },
    messages: [{
      type: {
        type: String,
        enum: ['user', 'bot', 'system'],
        required: true
      },
      message: {
        type: String,
        required: true
      },
      userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      timestamp: {
        type: Date,
        default: Date.now
      },
      metadata: mongoose.Schema.Types.Mixed
    }],
    insights: {
      commonQuestions: [String],
      popularTopics: [String],
      userSentiment: {
        positive: { type: Number, default: 0 },
        neutral: { type: Number, default: 0 },
        negative: { type: Number, default: 0 }
      }
    }
  },
  settings: {
    allowComments: {
      type: Boolean,
      default: true
    },
    allowReactions: {
      type: Boolean,
      default: true
    },
    moderationEnabled: {
      type: Boolean,
      default: false
    },
    recordingEnabled: {
      type: Boolean,
      default: false
    }
  },
  status: {
    type: String,
    enum: ['preparing', 'live', 'ended', 'error'],
    default: 'preparing'
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for performance
liveStreamSchema.index({ eventId: 1, isActive: 1 });
liveStreamSchema.index({ hostId: 1 });
liveStreamSchema.index({ startTime: -1 });
liveStreamSchema.index({ status: 1 });

// Virtual for current duration
liveStreamSchema.virtual('currentDuration').get(function() {
  if (this.isActive && this.startTime) {
    return Math.floor((new Date() - this.startTime) / 1000);
  }
  return this.duration || 0;
});

// Virtual for current viewer count
liveStreamSchema.virtual('currentViewerCount').get(function() {
  return this.viewers.filter(viewer => !viewer.leaveTime).length;
});

// Pre-save middleware to update analytics
liveStreamSchema.pre('save', function(next) {
  // Update max concurrent viewers
  const currentViewers = this.viewers.filter(viewer => !viewer.leaveTime).length;
  if (currentViewers > this.analytics.maxConcurrentViewers) {
    this.analytics.maxConcurrentViewers = currentViewers;
  }
  
  // Update total viewers
  this.analytics.totalViewers = Math.max(this.analytics.totalViewers, this.viewers.length);
  
  // Calculate total view time
  let totalViewTime = 0;
  this.viewers.forEach(viewer => {
    if (viewer.leaveTime) {
      totalViewTime += Math.floor((viewer.leaveTime - viewer.joinTime) / 1000);
    } else if (this.isActive) {
      totalViewTime += Math.floor((new Date() - viewer.joinTime) / 1000);
    }
  });
  this.analytics.totalViewTime = totalViewTime;
  
  // Calculate average view time
  if (this.analytics.totalViewers > 0) {
    this.analytics.averageViewTime = this.analytics.totalViewTime / this.analytics.totalViewers;
  }
  
  // Calculate engagement rate
  if (this.analytics.totalViewers > 0) {
    this.analytics.engagementRate = (this.analytics.engagementEvents.length / this.analytics.totalViewers) * 100;
  }
  
  next();
});

// Static methods
liveStreamSchema.statics.findActiveLiveStream = function(eventId) {
  return this.findOne({
    eventId,
    isActive: true,
    status: { $in: ['preparing', 'live'] }
  }).populate('hostId', 'username fullName profilePicture');
};

liveStreamSchema.statics.findByRoomId = function(roomId) {
  return this.findOne({ roomId })
    .populate('hostId', 'username fullName profilePicture')
    .populate('eventId', 'eventName eventDescription eventLocation images');
};

liveStreamSchema.statics.getEventLiveStreams = function(eventId, limit = 10) {
  return this.find({ eventId })
    .sort({ startTime: -1 })
    .limit(limit)
    .populate('hostId', 'username fullName profilePicture')
    .select('-viewers -analytics.engagementEvents -chatbotData.messages');
};

liveStreamSchema.statics.getHostLiveStreams = function(hostId, limit = 20) {
  return this.find({ hostId })
    .sort({ startTime: -1 })
    .limit(limit)
    .populate('eventId', 'eventName eventDescription images')
    .select('-viewers -chatbotData.messages');
};

// Instance methods
liveStreamSchema.methods.addViewer = function(userId) {
  const existingViewer = this.viewers.find(
    viewer => viewer.userId.toString() === userId.toString() && !viewer.leaveTime
  );
  
  if (!existingViewer) {
    this.viewers.push({
      userId,
      joinTime: new Date()
    });
  }
  
  return this.save();
};

liveStreamSchema.methods.removeViewer = function(userId) {
  const viewer = this.viewers.find(
    viewer => viewer.userId.toString() === userId.toString() && !viewer.leaveTime
  );
  
  if (viewer) {
    viewer.leaveTime = new Date();
    viewer.totalViewTime = Math.floor((viewer.leaveTime - viewer.joinTime) / 1000);
  }
  
  return this.save();
};

liveStreamSchema.methods.addEngagementEvent = function(eventData) {
  this.analytics.engagementEvents.push(eventData);
  return this.save();
};

liveStreamSchema.methods.endStream = function() {
  this.isActive = false;
  this.endTime = new Date();
  this.status = 'ended';
  this.duration = Math.floor((this.endTime - this.startTime) / 1000);
  
  // Mark all active viewers as left
  this.viewers.forEach(viewer => {
    if (!viewer.leaveTime) {
      viewer.leaveTime = this.endTime;
      viewer.totalViewTime = Math.floor((viewer.leaveTime - viewer.joinTime) / 1000);
    }
  });
  
  return this.save();
};

// TODO: Chatbot related methods (for future implementation)
/*
liveStreamSchema.methods.addChatbotMessage = function(messageData) {
  this.chatbotData.messages.push(messageData);
  
  // Limit messages to last 1000 for performance
  if (this.chatbotData.messages.length > 1000) {
    this.chatbotData.messages = this.chatbotData.messages.slice(-1000);
  }
  
  return this.save();
};

liveStreamSchema.methods.updateChatbotInsights = function(insights) {
  this.chatbotData.insights = { ...this.chatbotData.insights, ...insights };
  return this.save();
};
*/

const LiveStream = mongoose.model('LiveStream', liveStreamSchema);

module.exports = { LiveStream };