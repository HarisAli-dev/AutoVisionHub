const { zegoChatbotService } = require('../services/zegoChatbotService');
const { liveStreamService } = require('../services/liveStreamService');

const zegoChatbotController = {
  /**
   * Generate ZEGO authentication token
   * GET /api/zego/token
   */
  generateToken: async (req, res) => {
    try {
      const { user_id, effective_time } = req.query;
      
      if (!user_id) {
        return res.status(400).json({
          success: false,
          message: 'user_id is required'
        });
      }

      const effectiveTime = effective_time ? parseInt(effective_time) : 86400; // Default 24 hours
      
      const token = zegoChatbotService.generateToken(user_id, effectiveTime);

      res.status(200).json({
        success: true,
        data: {
          token,
          user_id,
          app_id: process.env.ZEGO_APP_ID,
          effective_time: effectiveTime,
          expires_at: new Date(Date.now() + effectiveTime * 1000).toISOString()
        }
      });

    } catch (error) {
      console.error('Error generating ZEGO token:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to generate token',
        error: error.message
      });
    }
  },

  /**
   * Register AI Agent
   * POST /api/zego/chatbot/register
   */
  registerAgent: async (req, res) => {
    try {
      const customConfig = req.body;
      
      const result = await zegoChatbotService.registerAgent(customConfig);

      res.status(200).json({
        success: true,
        message: 'AI Agent registered successfully',
        data: result
      });

    } catch (error) {
      console.error('Error registering AI Agent:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to register AI Agent',
        error: error.message
      });
    }
  },

  /**
   * Start chatbot session for a live stream
   * POST /api/zego/chatbot/start
   */
  startChatbot: async (req, res) => {
    try {
      const { room_id, host_user_id, options } = req.body;
      const userId = req.user?._id || host_user_id;

      if (!room_id) {
        return res.status(400).json({
          success: false,
          message: 'room_id is required'
        });
      }

      // Verify the live stream exists and is active
      const liveStream = await liveStreamService.getLiveStreamByRoomId(room_id);
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

      // Check if chatbot is already active for this room
      const existingChatbot = zegoChatbotService.getChatbotStatus(room_id);
      if (existingChatbot) {
        return res.status(200).json({
          success: true,
          message: 'Chatbot already active for this room',
          data: existingChatbot
        });
      }

      // Start the chatbot session
      const chatbotInstance = await zegoChatbotService.startChatbotSession(
        room_id,
        userId.toString(),
        options
      );

      // Update live stream record to include chatbot info
      await liveStreamService.updateLiveStream(room_id, {
        'chatbot.isActive': true,
        'chatbot.instanceId': chatbotInstance.instanceId,
        'chatbot.startTime': new Date()
      });

      res.status(201).json({
        success: true,
        message: 'Chatbot started successfully',
        data: chatbotInstance
      });

    } catch (error) {
      console.error('Error starting chatbot:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to start chatbot',
        error: error.message
      });
    }
  },

  /**
   * Stop chatbot session
   * POST /api/zego/chatbot/stop
   */
  stopChatbot: async (req, res) => {
    try {
      const { room_id, chatbot_id } = req.body;
      
      const roomIdToStop = room_id || chatbot_id;

      if (!roomIdToStop) {
        return res.status(400).json({
          success: false,
          message: 'room_id or chatbot_id is required'
        });
      }

      const result = await zegoChatbotService.stopChatbotSession(roomIdToStop);

      if (!result.success) {
        return res.status(404).json(result);
      }

      // Update live stream record
      try {
        await liveStreamService.updateLiveStream(roomIdToStop, {
          'chatbot.isActive': false,
          'chatbot.endTime': new Date(),
          'chatbot.messagesCount': result.messagesCount
        });
      } catch (updateError) {
        console.warn('Could not update live stream chatbot status:', updateError.message);
      }

      res.status(200).json({
        success: true,
        message: 'Chatbot stopped successfully',
        data: result
      });

    } catch (error) {
      console.error('Error stopping chatbot:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to stop chatbot',
        error: error.message
      });
    }
  },

  /**
   * Send message to chatbot
   * POST /api/zego/chatbot/message
   */
  sendMessage: async (req, res) => {
    try {
      const { room_id, message } = req.body;
      const userId = req.user?._id?.toString();
      const userName = req.user?.name || 'User';

      if (!room_id || !message) {
        return res.status(400).json({
          success: false,
          message: 'room_id and message are required'
        });
      }

      const response = await zegoChatbotService.sendMessageToChatbot(
        room_id,
        message,
        userId,
        userName
      );

      res.status(200).json({
        success: true,
        message: 'Message sent to chatbot',
        data: response
      });

    } catch (error) {
      console.error('Error sending message to chatbot:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to send message to chatbot',
        error: error.message
      });
    }
  },

  /**
   * Get chatbot status
   * GET /api/zego/chatbot/status/:roomId
   */
  getChatbotStatus: async (req, res) => {
    try {
      const { roomId } = req.params;

      const status = zegoChatbotService.getChatbotStatus(roomId);

      if (!status) {
        return res.status(200).json({
          success: true,
          data: {
            isActive: false,
            message: 'No active chatbot session found'
          }
        });
      }

      res.status(200).json({
        success: true,
        data: {
          isActive: true,
          ...status
        }
      });

    } catch (error) {
      console.error('Error getting chatbot status:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get chatbot status',
        error: error.message
      });
    }
  },

  /**
   * Get all active chatbots
   * GET /api/zego/chatbot/active
   */
  getActiveChatbots: async (req, res) => {
    try {
      const activeChatbots = zegoChatbotService.getAllActiveChatbots();

      res.status(200).json({
        success: true,
        data: {
          count: activeChatbots.length,
          chatbots: activeChatbots
        }
      });

    } catch (error) {
      console.error('Error getting active chatbots:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get active chatbots',
        error: error.message
      });
    }
  },

  /**
   * Update chatbot configuration
   * PUT /api/zego/chatbot/config
   */
  updateChatbotConfig: async (req, res) => {
    try {
      const { room_id, config } = req.body;

      if (!room_id || !config) {
        return res.status(400).json({
          success: false,
          message: 'room_id and config are required'
        });
      }

      const result = await zegoChatbotService.updateChatbotConfig(room_id, config);

      res.status(200).json({
        success: true,
        message: 'Chatbot configuration updated',
        data: result
      });

    } catch (error) {
      console.error('Error updating chatbot config:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update chatbot configuration',
        error: error.message
      });
    }
  }
};

module.exports = { zegoChatbotController };
