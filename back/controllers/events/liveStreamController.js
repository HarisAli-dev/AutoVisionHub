const { liveStreamService } = require('../../services/liveStreamService');
const Event = require('../../models/events/eventModel');

const liveStreamController = {
  // Start a new live stream for an event
  startLiveStream: async (req, res) => {
    try {
      const { eventId, streamTitle, streamDescription } = req.body;
      const userId = req.user._id;

      // Validate input
      if (!eventId || !streamTitle) {
        return res.status(400).json({
          success: false,
          message: 'Event ID and stream title are required'
        });
      }

      // Check if user is the event creator
      const event = await Event.findById(eventId);
      if (!event) {
        return res.status(404).json({
          success: false,
          message: 'Event not found'
        });
      }

      if (event.createdBy.toString() !== userId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Only event creator can start live stream'
        });
      }

      // Check if there's already an active live stream for this event
      const existingStream = await liveStreamService.getActiveLiveStream(eventId);
      if (existingStream) {
        return res.status(400).json({
          success: false,
          message: 'Live stream is already active for this event',
          data: { roomId: existingStream.roomId }
        });
      }

      // Generate unique room ID
      const roomId = `live_${eventId}_${Date.now()}`;

      // Create live stream record
      const liveStream = await liveStreamService.createLiveStream({
        eventId,
        roomId,
        hostId: userId,
        streamTitle: streamTitle.trim(),
        streamDescription: streamDescription?.trim() || '',
        isActive: true,
        startTime: new Date(),
        viewers: [],
        analytics: {
          totalViewers: 0,
          maxConcurrentViewers: 0,
          totalViewTime: 0,
          engagementEvents: []
        }
      });

      // TODO: Initialize chatbot for this live stream
      // await chatbotService.initializeForLiveStream(roomId, eventId);

      res.status(201).json({
        success: true,
        message: 'Live stream started successfully',
        data: {
          roomId,
          liveStreamId: liveStream._id,
          event: {
            id: event._id,
            name: event.eventName,
            description: event.eventDescription
          }
        }
      });

    } catch (error) {
      console.error('Error starting live stream:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to start live stream',
        error: error.message
      });
    }
  },

  // Join an existing live stream
  joinLiveStream: async (req, res) => {
    try {
      const { roomId } = req.params;
      const userId = req.user._id;

      // Find the live stream
      const liveStream = await liveStreamService.getLiveStreamByRoomId(roomId);
      if (!liveStream) {
        return res.status(404).json({
          success: false,
          message: 'Live stream not found'
        });
      }

      if (!liveStream.isActive) {
        return res.status(400).json({
          success: false,
          message: 'Live stream is not active'
        });
      }

      // Add user to viewers if not already present
      const isAlreadyViewing = liveStream.viewers.some(
        viewer => viewer.userId.toString() === userId.toString()
      );

      if (!isAlreadyViewing) {
        await liveStreamService.addViewer(roomId, userId);
      }

      // Join user to Socket.IO room for real-time events
      try {
        const socket = require('../../config/socket');
        const io = socket.getIO();
        // Note: The actual socket connection will handle room joining on the client side
        // We're just logging here for backend awareness
        console.log(`User ${userId} joining live stream room ${roomId}`);
      } catch (socketError) {
        console.warn('Socket.IO not available for room joining:', socketError.message);
      }

      // Get event details
      const event = await Event.findById(liveStream.eventId).select('eventName eventDescription eventLocation images');

      // TODO: Notify chatbot that user joined
      // await chatbotService.notifyUserJoined(roomId, userId);

      res.status(200).json({
        success: true,
        message: 'Successfully joined live stream',
        data: {
          roomId,
          liveStream: {
            id: liveStream._id,
            title: liveStream.streamTitle,
            description: liveStream.streamDescription,
            startTime: liveStream.startTime,
            viewerCount: liveStream.viewers.length,
            isHost: liveStream.hostId.toString() === userId.toString()
          },
          event
        }
      });

    } catch (error) {
      console.error('Error joining live stream:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to join live stream',
        error: error.message
      });
    }
  },

  // Stop a live stream
  stopLiveStream: async (req, res) => {
    try {
        console.log('Received request to stop live stream');
      const { roomId } = req.params;
      const userId = req.user._id;

      // Find the live stream
      const liveStream = await liveStreamService.getLiveStreamByRoomId(roomId);
      if (!liveStream) {
        return res.status(404).json({
          success: false,
          message: 'Live stream not found'
        });
      }

      if (!liveStream.isActive) {
        return res.status(400).json({
          success: false,
          message: 'Live stream is already stopped'
        });
      }

      // Calculate duration
      const endTime = new Date();
      const duration = Math.floor((endTime - liveStream.startTime) / 1000); // in seconds

      // Stop the live stream
      await liveStreamService.stopLiveStream(roomId, {
        endTime,
        duration,
        finalViewerCount: liveStream.viewers.length
      });

      // Notify all viewers that the stream has ended via Socket.IO
      try {
        const socket = require('../../config/socket');
        const io = socket.getIO();
        
        // Use the more comprehensive notification system
        io.to(roomId).emit('liveStreamEnded', {
          roomId,
          message: 'The live stream has ended',
          hostId: userId,
          timestamp: new Date().toISOString(),
          reason: 'host_stopped_recording'
        });
        
        // Also emit recording status change
        io.to(roomId).emit('recordingStatusChanged', {
          roomId,
          status: 'stopped',
          hostId: userId,
          timestamp: new Date().toISOString()
        });
        
        console.log(`Notified viewers that live stream ${roomId} has ended`);
      } catch (socketError) {
        console.warn('Could not notify viewers via socket:', socketError.message);
      }

      // TODO: Process analytics with chatbot
      // await chatbotService.processLiveStreamEnded(roomId, liveStream.analytics);

      res.status(200).json({
        success: true,
        message: 'Live stream stopped successfully',
        data: {
          duration,
          totalViewers: liveStream.analytics.totalViewers,
          maxConcurrentViewers: liveStream.analytics.maxConcurrentViewers
        }
      });

    } catch (error) {
      console.error('Error stopping live stream:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to stop live stream',
        error: error.message
      });
    }
  },

  // Get live stream status
  getLiveStreamStatus: async (req, res) => {
    try {
      const { eventId } = req.params;

      const liveStream = await liveStreamService.getActiveLiveStream(eventId);
      
      if (!liveStream) {
        return res.status(200).json({
          success: true,
          data: {
            isActive: false,
            roomId: null,
            status: null
          }
        });
      }

      // Calculate current duration
      const currentTime = new Date();
      const duration = Math.floor((currentTime - liveStream.startTime) / 1000);

      res.status(200).json({
        success: true,
        data: {
          isActive: liveStream.isActive,
          roomId: liveStream.roomId,
          status: {
            title: liveStream.streamTitle,
            description: liveStream.streamDescription,
            startTime: liveStream.startTime,
            duration,
            viewerCount: liveStream.viewers.length,
            maxConcurrentViewers: liveStream.analytics.maxConcurrentViewers,
            isHost: req.user && liveStream.hostId.toString() === req.user._id.toString()
          }
        }
      });

    } catch (error) {
      console.error('Error getting live stream status:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get live stream status',
        error: error.message
      });
    }
  },

  // Leave a live stream (for viewers)
  leaveLiveStream: async (req, res) => {
    try {
      const { roomId } = req.params;
      const userId = req.user._id;

      const liveStream = await liveStreamService.getLiveStreamByRoomId(roomId);
      if (!liveStream) {
        return res.status(404).json({
          success: false,
          message: 'Live stream not found'
        });
      }

      // Remove user from viewers
      await liveStreamService.removeViewer(roomId, userId);

      // TODO: Notify chatbot that user left
      // await chatbotService.notifyUserLeft(roomId, userId);

      res.status(200).json({
        success: true,
        message: 'Successfully left live stream'
      });

    } catch (error) {
      console.error('Error leaving live stream:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to leave live stream',
        error: error.message
      });
    }
  },

  // Get live stream analytics (for hosts)
  getLiveStreamAnalytics: async (req, res) => {
    try {
      const { roomId } = req.params;
      const userId = req.user._id;

      const liveStream = await liveStreamService.getLiveStreamByRoomId(roomId);
      if (!liveStream) {
        return res.status(404).json({
          success: false,
          message: 'Live stream not found'
        });
      }

      // Check if user is the host
      if (liveStream.hostId.toString() !== userId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Only the host can view analytics'
        });
      }

      // Calculate additional analytics
      const analytics = await liveStreamService.calculateAnalytics(roomId);

      res.status(200).json({
        success: true,
        data: {
          analytics: {
            ...liveStream.analytics,
            ...analytics,
            averageViewTime: analytics.totalViewTime / Math.max(analytics.totalViewers, 1),
            engagementRate: (analytics.engagementEvents.length / Math.max(analytics.totalViewers, 1)) * 100
          },
          streamInfo: {
            title: liveStream.streamTitle,
            startTime: liveStream.startTime,
            endTime: liveStream.endTime,
            isActive: liveStream.isActive
          }
        }
      });

    } catch (error) {
      console.error('Error getting live stream analytics:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get live stream analytics',
        error: error.message
      });
    }
  },

  // Record engagement event (likes, comments, etc.)
  recordEngagementEvent: async (req, res) => {
    try {
      const { roomId } = req.params;
      const { eventType, data } = req.body;
      const userId = req.user._id;

      if (!eventType) {
        return res.status(400).json({
          success: false,
          message: 'Event type is required'
        });
      }

      const liveStream = await liveStreamService.getLiveStreamByRoomId(roomId);
      if (!liveStream || !liveStream.isActive) {
        return res.status(404).json({
          success: false,
          message: 'Active live stream not found'
        });
      }

      // Record engagement event
      await liveStreamService.recordEngagementEvent(roomId, {
        userId,
        eventType,
        data,
        timestamp: new Date()
      });

      // TODO: Process engagement with chatbot
      // await chatbotService.processEngagement(roomId, eventType, userId, data);

      res.status(200).json({
        success: true,
        message: 'Engagement event recorded successfully'
      });

    } catch (error) {
      console.error('Error recording engagement event:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to record engagement event',
        error: error.message
      });
    }
  }
};

module.exports = { liveStreamController };