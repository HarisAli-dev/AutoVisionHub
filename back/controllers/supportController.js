const supportService = require('../services/supportService');

const supportController = {
  // Handle AI chatbot conversations
  handleChatbot: async (req, res) => {
    try {
      const { message, userId, context } = req.body;

      if (!message || !userId) {
        return res.status(400).json({
          success: false,
          message: 'Message and userId are required'
        });
      }

      // Get AI response from support service
      const aiResponse = await supportService.generateAIResponse({
        userMessage: message,
        userId,
        context: context || 'general',
        userHistory: req.user || null
      });

      // Log the conversation for analytics
      await supportService.logConversation({
        userId,
        userMessage: message,
        aiResponse,
        context,
        timestamp: new Date()
      });

      res.status(200).json({
        success: true,
        response: aiResponse,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      console.error('Error in chatbot handler:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to generate response',
        error: error.message
      });
    }
  },

  // Get conversation history
  getConversationHistory: async (req, res) => {
    try {
      const { userId } = req.params;
      const { limit = 50 } = req.query;

      const conversations = await supportService.getConversationHistory(userId, parseInt(limit));

      res.status(200).json({
        success: true,
        data: conversations
      });

    } catch (error) {
      console.error('Error getting conversation history:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get conversation history',
        error: error.message
      });
    }
  },

  // Submit feedback on AI response
  submitFeedback: async (req, res) => {
    try {
      const { conversationId, rating, feedback } = req.body;

      if (!conversationId || !rating) {
        return res.status(400).json({
          success: false,
          message: 'Conversation ID and rating are required'
        });
      }

      await supportService.submitFeedback({
        conversationId,
        rating,
        feedback,
        userId: req.user._id
      });

      res.status(200).json({
        success: true,
        message: 'Feedback submitted successfully'
      });

    } catch (error) {
      console.error('Error submitting feedback:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to submit feedback',
        error: error.message
      });
    }
  },

  // Escalate to human support
  escalateToHuman: async (req, res) => {
    try {
      const { message, category, priority } = req.body;
      const userId = req.user._id;

      const ticket = await supportService.createSupportTicket({
        userId,
        message,
        category: category || 'general',
        priority: priority || 'medium',
        source: 'chatbot_escalation'
      });

      res.status(201).json({
        success: true,
        message: 'Support ticket created successfully',
        ticketId: ticket._id
      });

    } catch (error) {
      console.error('Error escalating to human support:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to create support ticket',
        error: error.message
      });
    }
  }
};

module.exports = supportController;