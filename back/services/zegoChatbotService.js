const axios = require('axios');
const crypto = require('crypto');
const { GoogleGenerativeAI } = require('@google/generative-ai');

class ZegoChatbotService {
  constructor() {
    this.appId = process.env.ZEGO_APP_ID;
    this.serverSecret = process.env.ZEGO_SERVER_SECRET;
    this.apiBaseUrl = process.env.ZEGO_API_BASE_URL || 'https://rtc-api.zego.im';
    
    // Store active chatbot instances and chat history
    this.activeChatbots = new Map();
    this.chatHistory = new Map();
    
    // Initialize Gemini AI
    const apiKey = process.env.GEMINI_API_KEY;
    console.log('🔑 Checking Gemini API key...');
    console.log('    API key exists:', !!apiKey);
    console.log('    API key length:', apiKey ? apiKey.length : 0);
    
    if (apiKey && apiKey.trim().length > 20) {
      try {
        this.genAI = new GoogleGenerativeAI(apiKey.trim());
        this.model = this.genAI.getGenerativeModel({ 
          model: "gemini-2.0-flash-exp",
          generationConfig: {
            temperature: 0.7,
            topP: 0.8,
            topK: 40,
            maxOutputTokens: 150,
          },
          systemInstruction: `You are AutoVision AI Assistant, a helpful and friendly AI companion for automotive live streams. 
Rules:
- Keep responses VERY brief (1-2 sentences max, under 100 words)
- Be friendly and engaging with viewers
- Focus on automotive topics when relevant
- Use emojis occasionally 🚗
- If asked about the stream, encourage discussion
- Be conversational and natural`
        });
        console.log('✅ Gemini AI chatbot initialized for live streams');
      } catch (error) {
        console.error('⚠️ Failed to initialize Gemini AI:', error.message);
        this.model = null;
      }
    } else {
      console.warn('⚠️ Gemini API key not configured. Using fallback responses.');
      console.warn('    API key length:', apiKey ? apiKey.length : 0);
      console.warn('    Get your API key from: https://aistudio.google.com/app/apikey');
      console.warn('    For Digital Ocean: Add GEMINI_API_KEY to App Platform environment variables');
      this.model = null;
    }
  }

  /**
   * Generate fallback response when AI is unavailable
   */
  _getFallbackResponse(message) {
    const lowerMessage = message.toLowerCase();
    
    if (lowerMessage.includes('hello') || lowerMessage.includes('hi')) {
      return "Hello! 👋 Welcome to the stream!";
    }
    if (lowerMessage.includes('car') || lowerMessage.includes('vehicle')) {
      return "Great question about cars! 🚗 The host might have more details!";
    }
    if (lowerMessage.includes('thank')) {
      return "You're welcome! Happy to help! 😊";
    }
    if (lowerMessage.includes('help')) {
      return "I'm here to assist! Feel free to ask questions about the stream. 💬";
    }
    
    return "Thanks for your message! The host will respond shortly. 😊";
  }

  /**
   * Generate authentication token for ZEGOCLOUD
   * @param {string} userId - User ID
   * @param {number} effectiveTimeInSeconds - Token validity duration (default 24 hours)
   * @returns {string} Authentication token
   */
  generateToken(userId, effectiveTimeInSeconds = 86400) {
    if (!this.appId || !this.serverSecret) {
      throw new Error('ZEGO_APP_ID and ZEGO_SERVER_SECRET must be configured');
    }

    const time = Math.floor(Date.now() / 1000);
    const nonce = Math.floor(Math.random() * 1000000);
    
    // Create payload
    const payload = {
      app_id: parseInt(this.appId),
      user_id: userId,
      nonce: nonce,
      ctime: time,
      expire: time + effectiveTimeInSeconds
    };

    // Generate signature
    const body = JSON.stringify(payload);
    const signature = crypto
      .createHmac('sha256', this.serverSecret)
      .update(body)
      .digest('hex');

    // Encode token
    const tokenData = {
      ...payload,
      signature
    };

    return Buffer.from(JSON.stringify(tokenData)).toString('base64');
  }

  /**
   * Register AI Agent with ZEGOCLOUD
   * @param {Object} customConfig - Custom agent configuration (optional)
   * @returns {Promise<Object>} Registration response
   */
  async registerAgent(customConfig = {}) {
    console.log('✅ Gemini-powered chatbot ready (no external registration needed)');
    return { 
      success: true, 
      message: 'Chatbot uses local Gemini AI',
      agentId: 'gemini-assistant'
    };
  }

  /**
   * Generate AI response using Gemini
   */
  async generateAIResponse(message, roomId, userName) {
    if (!this.model) {
      return this._getFallbackResponse(message);
    }

    try {
      // Get or initialize chat history for this room
      if (!this.chatHistory.has(roomId)) {
        this.chatHistory.set(roomId, []);
      }
      const history = this.chatHistory.get(roomId);

      // Build user prompt
      const userPrompt = `User "${userName}" says: "${message}"`;

      // Generate response
      const chat = this.model.startChat({
        history: history.slice(-10), // Keep last 10 exchanges for context
      });

      const result = await chat.sendMessage(userPrompt);
      const response = result.response.text();

      // Update history
      history.push(
        { role: 'user', parts: [{ text: userPrompt }] },
        { role: 'model', parts: [{ text: response }] }
      );

      // Keep history manageable (max 20 messages)
      if (history.length > 20) {
        this.chatHistory.set(roomId, history.slice(-20));
      }

      console.log(`🤖 AI Response: "${response.substring(0, 50)}..."`);
      return response;

    } catch (error) {
      console.error('❌ Error generating AI response:', error.message);
      return this._getFallbackResponse(message);
    }
  }

  /**
   * Start chatbot session for a live stream room
   * @param {string} roomId - Live stream room ID
   * @param {string} hostUserId - Host user ID
   * @param {Object} options - Additional options
   * @returns {Promise<Object>} Chatbot instance details
   */
  async startChatbotSession(roomId, hostUserId, options = {}) {
    try {
      console.log(`🚀 Starting Gemini chatbot session for room: ${roomId}`);
      
      // Generate unique agent user ID
      const agentUserId = `ai-bot-${roomId}`;
      const agentStreamId = `ai-stream-${roomId}`;
      
      // Store active chatbot instance
      this.activeChatbots.set(roomId, {
        instanceId: `gemini-${Date.now()}`,
        agentUserId,
        agentStreamId,
        roomId,
        hostUserId,
        startTime: new Date(),
        messagesCount: 0,
        welcomeMessage: options.welcomeMessage || "Hello everyone! 👋 I'm the AI assistant. Feel free to ask me questions!"
      });

      // Initialize chat history for this room
      this.chatHistory.set(roomId, []);

      console.log(`✅ Gemini chatbot session started for room ${roomId}`);
      
      return {
        instanceId: `gemini-${Date.now()}`,
        agentUserId,
        agentStreamId,
        roomId,
        status: 'active',
        welcomeMessage: this.activeChatbots.get(roomId).welcomeMessage
      };
      
    } catch (error) {
      console.error('❌ Error starting chatbot session:', error.message);
      throw new Error(`Failed to start chatbot session: ${error.message}`);
    }
  }

  /**
   * Stop chatbot session
   * @param {string} roomId - Room ID or Instance ID
   * @returns {Promise<Object>} Stop response
   */
  async stopChatbotSession(roomId) {
    try {
      const chatbotInstance = this.activeChatbots.get(roomId);
      
      if (!chatbotInstance) {
        console.warn(`⚠️ No active chatbot found for room: ${roomId}`);
        return { success: false, message: 'No active chatbot session found' };
      }

      console.log(`🛑 Stopping chatbot session for room: ${roomId}`);

      // Remove from active chatbots and clear history
      this.activeChatbots.delete(roomId);
      this.chatHistory.delete(roomId);

      console.log(`✅ Chatbot session stopped successfully for room ${roomId}`);
      
      return {
        success: true,
        message: 'Chatbot session stopped',
        instanceId: chatbotInstance.instanceId,
        duration: Math.floor((new Date() - chatbotInstance.startTime) / 1000),
        messagesCount: chatbotInstance.messagesCount
      };
      
    } catch (error) {
      console.error('❌ Error stopping chatbot session:', error.message);
      throw new Error(`Failed to stop chatbot session: ${error.message}`);
    }
  }

  /**
   * Send message to chatbot and get AI response
   * @param {string} roomId - Room ID
   * @param {string} message - Message text
   * @param {string} userId - User ID who sent the message
   * @param {string} userName - User name who sent the message
   * @returns {Promise<Object>} Response with AI reply
   */
  async sendMessageToChatbot(roomId, message, userId, userName = 'User') {
    try {
      const chatbotInstance = this.activeChatbots.get(roomId);
      
      if (!chatbotInstance) {
        throw new Error('No active chatbot session found for this room');
      }

      console.log(`💬 Processing message in room ${roomId}: "${message}"`);

      // Generate AI response
      const aiResponse = await this.generateAIResponse(message, roomId, userName);

      // Increment message count
      chatbotInstance.messagesCount++;

      console.log(`✅ AI response generated successfully`);
      
      return {
        success: true,
        response: aiResponse,
        agentUserId: chatbotInstance.agentUserId,
        timestamp: Date.now()
      };
      
    } catch (error) {
      console.error('❌ Error processing chatbot message:', error.message);
      throw new Error(`Failed to process message: ${error.message}`);
    }
  }

  /**
   * Get chatbot session status
   * @param {string} roomId - Room ID
   * @returns {Object|null} Chatbot instance details
   */
  getChatbotStatus(roomId) {
    const instance = this.activeChatbots.get(roomId);
    
    if (!instance) {
      return null;
    }

    return {
      ...instance,
      uptime: Math.floor((new Date() - instance.startTime) / 1000),
      isActive: true
    };
  }

  /**
   * Get all active chatbot sessions
   * @returns {Array} List of active chatbot sessions
   */
  getAllActiveChatbots() {
    const activeSessions = [];
    
    this.activeChatbots.forEach((instance, roomId) => {
      activeSessions.push({
        roomId,
        ...instance,
        uptime: Math.floor((new Date() - instance.startTime) / 1000)
      });
    });

    return activeSessions;
  }

  /**
   * Update chatbot configuration
   * @param {string} roomId - Room ID
   * @param {Object} config - New configuration
   * @returns {Promise<Object>} Update response
   */
  async updateChatbotConfig(roomId, config) {
    try {
      const chatbotInstance = this.activeChatbots.get(roomId);
      
      if (!chatbotInstance) {
        throw new Error('No active chatbot session found for this room');
      }

      console.log(`⚙️ Updating chatbot configuration for room ${roomId}`);

      // Update instance config
      if (config.welcomeMessage) {
        chatbotInstance.welcomeMessage = config.welcomeMessage;
      }

      console.log(`✅ Chatbot configuration updated successfully`);
      
      return {
        success: true,
        message: 'Configuration updated',
        config: chatbotInstance
      };
      
    } catch (error) {
      console.error('❌ Error updating chatbot configuration:', error.message);
      throw new Error(`Failed to update chatbot configuration: ${error.message}`);
    }
  }
}

// Export singleton instance
const zegoChatbotService = new ZegoChatbotService();
module.exports = { zegoChatbotService, ZegoChatbotService };
