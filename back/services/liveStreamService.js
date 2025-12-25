const { LiveStream } = require('../models/events/liveStreamModel');

const liveStreamService = {
  // Create a new live stream
  createLiveStream: async (streamData) => {
    try {
      const liveStream = new LiveStream(streamData);
      await liveStream.save();
      return liveStream;
    } catch (error) {
      console.error('Error creating live stream:', error);
      throw error;
    }
  },

  // Get active live stream for an event
  getActiveLiveStream: async (eventId) => {
    try {
      return await LiveStream.findActiveLiveStream(eventId);
    } catch (error) {
      console.error('Error getting active live stream:', error);
      throw error;
    }
  },

  // Get live stream by room ID
  getLiveStreamByRoomId: async (roomId) => {
    try {
      return await LiveStream.findOne({ roomId });
    } catch (error) {
      console.error('Error getting live stream by room ID:', error);
      throw error;
    }
  },

  // Add viewer to live stream
  addViewer: async (roomId, userId) => {
    try {
      const liveStream = await LiveStream.findOne({ roomId });
      if (!liveStream) {
        throw new Error('Live stream not found');
      }

      await liveStream.addViewer(userId);
      
      // TODO: Notify chatbot about new viewer
      // await chatbotService.notifyNewViewer(roomId, userId);
      
      return liveStream;
    } catch (error) {
      console.error('Error adding viewer:', error);
      throw error;
    }
  },

  // Remove viewer from live stream
  removeViewer: async (roomId, userId) => {
    try {
      const liveStream = await LiveStream.findOne({ roomId });
      if (!liveStream) {
        throw new Error('Live stream not found');
      }

      await liveStream.removeViewer(userId);
      
      // TODO: Notify chatbot about viewer leaving
      // await chatbotService.notifyViewerLeft(roomId, userId);
      
      return liveStream;
    } catch (error) {
      console.error('Error removing viewer:', error);
      throw error;
    }
  },

  // Stop live stream
  stopLiveStream: async (roomId, endData = {}) => {
    try {
        console.log('Stopping live stream for room:', roomId, 'with endData:', endData);
      const liveStream = await LiveStream.findOne({ roomId });
      if (!liveStream) {
        throw new Error('Live stream not found');
      }

      // Update end data if provided
      if (endData.endTime) liveStream.endTime = endData.endTime;
      if (endData.duration) liveStream.duration = endData.duration;

      await liveStream.endStream();
      
      // TODO: Process final analytics with chatbot
      // await chatbotService.processStreamEnded(roomId, liveStream.analytics);
      console.log('Live stream ended and analytics processed');
      return liveStream;
    } catch (error) {
      console.error('Error stopping live stream:', error);
      throw error;
    }
  },

  // Record engagement event
  recordEngagementEvent: async (roomId, eventData) => {
    try {
      const liveStream = await LiveStream.findOne({ roomId });
      if (!liveStream) {
        throw new Error('Live stream not found');
      }

      await liveStream.addEngagementEvent(eventData);
      
      // TODO: Process engagement with chatbot
      // await chatbotService.processEngagement(roomId, eventData);
      
      return liveStream;
    } catch (error) {
      console.error('Error recording engagement event:', error);
      throw error;
    }
  },

  // Calculate detailed analytics
  calculateAnalytics: async (roomId) => {
    try {
      const liveStream = await LiveStream.findOne({ roomId });
      if (!liveStream) {
        throw new Error('Live stream not found');
      }

      const analytics = {
        totalViewers: liveStream.analytics.totalViewers,
        maxConcurrentViewers: liveStream.analytics.maxConcurrentViewers,
        totalViewTime: liveStream.analytics.totalViewTime,
        averageViewTime: liveStream.analytics.averageViewTime,
        engagementEvents: liveStream.analytics.engagementEvents.length,
        engagementRate: liveStream.analytics.engagementRate,
        
        // Detailed engagement breakdown
        engagementBreakdown: {},
        
        // Viewer retention data
        viewerRetention: {
          under30s: 0,
          under2min: 0,
          under5min: 0,
          over5min: 0
        },
        
        // Hourly analytics if stream was long enough
        hourlyViewers: [],
        
        // Peak viewing times
        peakViewingPeriods: []
      };

      // Calculate engagement breakdown
      liveStream.analytics.engagementEvents.forEach(event => {
        analytics.engagementBreakdown[event.eventType] = 
          (analytics.engagementBreakdown[event.eventType] || 0) + 1;
      });

      // Calculate viewer retention
      liveStream.viewers.forEach(viewer => {
        const viewTime = viewer.totalViewTime || 0;
        if (viewTime < 30) {
          analytics.viewerRetention.under30s++;
        } else if (viewTime < 120) {
          analytics.viewerRetention.under2min++;
        } else if (viewTime < 300) {
          analytics.viewerRetention.under5min++;
        } else {
          analytics.viewerRetention.over5min++;
        }
      });

      // Calculate hourly viewers for streams longer than 1 hour
      if (liveStream.duration > 3600) {
        const startTime = liveStream.startTime;
        const endTime = liveStream.endTime || new Date();
        const hours = Math.ceil((endTime - startTime) / (1000 * 60 * 60));
        
        for (let hour = 0; hour < hours; hour++) {
          const hourStart = new Date(startTime.getTime() + (hour * 60 * 60 * 1000));
          const hourEnd = new Date(hourStart.getTime() + (60 * 60 * 1000));
          
          const viewersInHour = liveStream.viewers.filter(viewer => {
            const joinTime = viewer.joinTime;
            const leaveTime = viewer.leaveTime || endTime;
            return joinTime < hourEnd && leaveTime > hourStart;
          }).length;
          
          analytics.hourlyViewers.push({
            hour: hour + 1,
            viewers: viewersInHour,
            timeRange: `${hourStart.toISOString()} - ${hourEnd.toISOString()}`
          });
        }
      }

      return analytics;
    } catch (error) {
      console.error('Error calculating analytics:', error);
      throw error;
    }
  },

  // Get live streams for an event
  getEventLiveStreams: async (eventId, limit = 10) => {
    try {
      return await LiveStream.getEventLiveStreams(eventId, limit);
    } catch (error) {
      console.error('Error getting event live streams:', error);
      throw error;
    }
  },

  // Get live streams for a host
  getHostLiveStreams: async (hostId, limit = 20) => {
    try {
      return await LiveStream.getHostLiveStreams(hostId, limit);
    } catch (error) {
      console.error('Error getting host live streams:', error);
      throw error;
    }
  },

  // Update live stream settings
  updateLiveStreamSettings: async (roomId, settings) => {
    try {
      const liveStream = await LiveStream.findOne({ roomId });
      if (!liveStream) {
        throw new Error('Live stream not found');
      }

      liveStream.settings = { ...liveStream.settings, ...settings };
      await liveStream.save();
      
      return liveStream;
    } catch (error) {
      console.error('Error updating live stream settings:', error);
      throw error;
    }
  },

  // Get live stream insights for dashboard
  getLiveStreamInsights: async (eventId, timeRange = '7d') => {
    try {
      const query = { eventId };
      
      // Add time range filter
      const now = new Date();
      const timeRangeMap = {
        '1d': 1,
        '7d': 7,
        '30d': 30,
        '90d': 90
      };
      const days = timeRangeMap[timeRange] || 7;
      const startDate = new Date(now.getTime() - (days * 24 * 60 * 60 * 1000));
      query.createdAt = { $gte: startDate };

      const liveStreams = await LiveStream.find(query)
        .sort({ startTime: -1 })
        .select('analytics duration startTime endTime status');

      const insights = {
        totalStreams: liveStreams.length,
        totalViewers: 0,
        totalViewTime: 0,
        averageDuration: 0,
        averageViewers: 0,
        totalEngagements: 0,
        streamsByStatus: {
          live: 0,
          ended: 0,
          error: 0
        },
        trends: {
          viewerGrowth: 0,
          engagementGrowth: 0
        }
      };

      liveStreams.forEach(stream => {
        insights.totalViewers += stream.analytics.totalViewers;
        insights.totalViewTime += stream.analytics.totalViewTime;
        insights.totalEngagements += stream.analytics.engagementEvents.length;
        insights.streamsByStatus[stream.status]++;
      });

      if (liveStreams.length > 0) {
        insights.averageDuration = liveStreams.reduce((sum, stream) => sum + (stream.duration || 0), 0) / liveStreams.length;
        insights.averageViewers = insights.totalViewers / liveStreams.length;
      }

      // TODO: Calculate trends using chatbot analytics
      // insights.trends = await chatbotService.calculateStreamTrends(eventId, timeRange);

      return insights;
    } catch (error) {
      console.error('Error getting live stream insights:', error);
      throw error;
    }
  },

  // TODO: Chatbot related service methods (for future implementation)
  /*
  addChatbotMessage: async (roomId, messageData) => {
    try {
      const liveStream = await LiveStream.findOne({ roomId });
      if (!liveStream) {
        throw new Error('Live stream not found');
      }

      await liveStream.addChatbotMessage(messageData);
      return liveStream;
    } catch (error) {
      console.error('Error adding chatbot message:', error);
      throw error;
    }
  },

  updateChatbotInsights: async (roomId, insights) => {
    try {
      const liveStream = await LiveStream.findOne({ roomId });
      if (!liveStream) {
        throw new Error('Live stream not found');
      }

      await liveStream.updateChatbotInsights(insights);
      return liveStream;
    } catch (error) {
      console.error('Error updating chatbot insights:', error);
      throw error;
    }
  },

  getChatbotMessages: async (roomId, limit = 50) => {
    try {
      const liveStream = await LiveStream.findOne({ roomId })
        .populate('chatbotData.messages.userId', 'username fullName profilePicture');
      
      if (!liveStream) {
        throw new Error('Live stream not found');
      }

      return liveStream.chatbotData.messages
        .slice(-limit)
        .sort((a, b) => a.timestamp - b.timestamp);
    } catch (error) {
      console.error('Error getting chatbot messages:', error);
      throw error;
    }
  }
  */
};

module.exports = { liveStreamService };