const { liveStreamService } = require('../../services/liveStreamService');
const { zegoChatbotService } = require('../../services/zegoChatbotService');
const { zegoRecordingService } = require('../../services/zegoRecordingService');
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

      // Initialize chatbot for this live stream
      try {
        const chatbotInstance = await zegoChatbotService.startChatbotSession(
          roomId,
          userId.toString(),
          {
            welcomeMessage: `Welcome to ${streamTitle}! I'm the AI Assistant here to help answer questions and engage with everyone.`
          }
        );
        
        console.log('✅ Chatbot initialized for live stream:', chatbotInstance);
      } catch (chatbotError) {
        console.error('⚠️ Failed to initialize chatbot (continuing without it):', chatbotError.message);
        // Continue without chatbot - non-critical feature
      }

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

      // Notify chatbot that user joined (if chatbot is active)
      try {
        const chatbotStatus = zegoChatbotService.getChatbotStatus(roomId);
        if (chatbotStatus) {
          console.log(`👤 User ${userId} joined live stream with active chatbot`);
          // Chatbot will automatically detect new viewers through ZEGO SDK
        }
      } catch (chatbotError) {
        console.warn('Could not notify chatbot of user join:', chatbotError.message);
      }

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

      // Stop chatbot session if active
      try {
        const chatbotResult = await zegoChatbotService.stopChatbotSession(roomId);
        if (chatbotResult.success) {
          console.log('✅ Chatbot session stopped:', chatbotResult);
        }
      } catch (chatbotError) {
        console.warn('Could not stop chatbot session:', chatbotError.message);
      }

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

      // Notify chatbot that user left (if chatbot is active)
      try {
        const chatbotStatus = zegoChatbotService.getChatbotStatus(roomId);
        if (chatbotStatus) {
          console.log(`👋 User ${userId} left live stream with active chatbot`);
          // Chatbot will automatically detect viewer leaving through ZEGO SDK
        }
      } catch (chatbotError) {
        console.warn('Could not notify chatbot of user leave:', chatbotError.message);
      }

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

      // Process engagement with chatbot (if active and relevant)
      try {
        const chatbotStatus = zegoChatbotService.getChatbotStatus(roomId);
        if (chatbotStatus && eventType === 'chat_message' && data?.message) {
          // If it's a chat message and mentions the bot, send to chatbot
          const message = data.message.toLowerCase();
          if (message.includes('bot') || message.includes('ai') || message.includes('assistant')) {
            const userName = req.user?.name || 'User';
            const botResponse = await zegoChatbotService.sendMessageToChatbot(
              roomId, 
              data.message, 
              userId,
              userName
            );
            
            // Emit bot response back to all clients in the room
            if (botResponse && botResponse.response) {
              const io = req.app.get('io');
              if (io) {
                io.to(roomId).emit('bot_message', {
                  message: botResponse.response,
                  senderId: chatbotStatus.agentUserId,
                  senderName: 'AI Bot',
                  timestamp: Date.now()
                });
                console.log('🤖 Bot response sent to room:', botResponse.response);
              }
            }
          }
        }
      } catch (chatbotError) {
        console.warn('Could not process engagement with chatbot:', chatbotError.message);
      }

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
  },

  // Upload recording
  uploadRecording: async (req, res) => {
    try {
      const { roomId } = req.params;
      const userId = req.user._id;

      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'No video file provided'
        });
      }

      // Verify the live stream exists and user is the host
      const liveStream = await liveStreamService.getLiveStreamByRoomId(roomId);
      if (!liveStream) {
        return res.status(404).json({
          success: false,
          message: 'Live stream not found'
        });
      }

      if (liveStream.hostId.toString() !== userId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Only the host can upload recording'
        });
      }

      // Upload to Cloudinary
      const recordingUrl = await zegoRecordingService.uploadRecording(
        req.file.path,
        roomId
      );

      // Save URL to database
      await liveStreamService.updateLiveStream(roomId, {
        recordingUrl
      });

      res.status(200).json({
        success: true,
        message: 'Recording uploaded successfully',
        data: { recordingUrl }
      });

    } catch (error) {
      console.error('Error uploading recording:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to upload recording',
        error: error.message
      });
    }
  },

  // Get recording
  getRecording: async (req, res) => {
    try {
      const { roomId } = req.params;

      const liveStream = await liveStreamService.getLiveStreamByRoomId(roomId);
      if (!liveStream) {
        return res.status(404).json({
          success: false,
          message: 'Live stream not found'
        });
      }

      if (!liveStream.recordingUrl) {
        return res.status(404).json({
          success: false,
          message: 'No recording available for this stream'
        });
      }

      res.status(200).json({
        success: true,
        data: {
          recordingUrl: liveStream.recordingUrl,
          streamTitle: liveStream.streamTitle,
          streamDescription: liveStream.streamDescription,
          startTime: liveStream.startTime,
          endTime: liveStream.endTime,
          duration: liveStream.duration
        }
      });

    } catch (error) {
      console.error('Error getting recording:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get recording',
        error: error.message
      });
    }
  }
};

module.exports = { liveStreamController };